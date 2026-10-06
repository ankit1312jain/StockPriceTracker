//
//  PriceStore.swift
//  StockPriceTracker
//
//  Single source of truth for live prices, shared across every screen.
//

import Foundation
import Observation

// MARK:  -  PriceStore  -

/// The single, observable source of truth for the app's live price data.
///
/// Both the list and the detail screen read from this one object (injected via
/// the SwiftUI environment), which is what makes price updates appear in
/// real time on **every** screen simultaneously with no duplicated state.
///
/// Isolated to `@MainActor` so all UI-facing mutations are main-thread-safe;
/// feed work happens off-main inside the `actor`-based ``PriceFeedProviding``.
@MainActor
@Observable
final class PriceStore {

    /// O(1) lookup of the latest stock by symbol.
    private(set) var stocksBySymbol: [String: Stock] = [:]

    /// Preserves the catalog's original ordering for stable display.
    private(set) var orderedSymbols: [String] = []

    private(set) var connectionStatus: ConnectionStatus = .disconnected

    /// Whether the catalog has finished loading (drives the loading state).
    private(set) var isLoaded = false

    /// Whether the user has the feed switched on (drives the Start/Stop button).
    ///
    /// This is the user's *intent* and deliberately survives backgrounding: the
    /// transport is suspended while backgrounded, but this flag is untouched so
    /// the feed resumes automatically on return to the foreground.
    private(set) var isFeedRunning = false

    /// Whether the scene is currently in the foreground. The live transport is
    /// only kept open while both this and `isFeedRunning` are `true`.
    private var isSceneActive = true

    private let catalog: SymbolCatalogProviding
    private let feed: PriceFeedProviding

    init(catalog: SymbolCatalogProviding, feed: PriceFeedProviding) {
        self.catalog = catalog
        self.feed = feed
    }

    // MARK:  -  Derived Access  -

    /// All stocks in catalog order.
    var stocks: [Stock] {
        orderedSymbols.compactMap { stocksBySymbol[$0] }
    }

    /// Looks up a single stock by symbol (used by the detail screen).
    func stock(for symbol: String) -> Stock? {
        stocksBySymbol[symbol]
    }

    // MARK:  -  Lifecycle  -

    /// Loads the catalog and begins observing feed events. Safe to call once;
    /// intended to be driven from the root view's `.task`.
    func activate() async {
        await loadCatalog()
        await observeEvents()
    }

    /// Exposed at `internal` access for deterministic unit testing.
    func loadCatalog() async {
        guard !isLoaded else { return }
        do {
            let symbols = try await catalog.loadSymbols()
            for stock in symbols { stocksBySymbol[stock.symbol] = stock }
            orderedSymbols = symbols.map(\.symbol)
            isLoaded = true
        } catch {
            // Catalog is bundled, so this is not expected; leave empty state.
            isLoaded = true
        }
    }

    /// Consumes the long-lived feed event stream and applies each event on the
    /// main actor. Returns only when the stream finishes (app teardown).
    private func observeEvents() async {
        for await event in feed.events {
            apply(event)
        }
    }

    // MARK:  -  Feed Control  -

    /// Starts the price feed (connects and begins streaming updates).
    func startFeed() {
        guard !isFeedRunning else { return }
        isFeedRunning = true
        if isSceneActive { launchFeed() }
    }

    /// Stops the price feed and disconnects.
    func stopFeed() {
        guard isFeedRunning else { return }
        isFeedRunning = false
        Task { await feed.stop() }
    }

    // MARK:  -  Scene Lifecycle  -

    /// Suspends the live transport when the app leaves the foreground, without
    /// clearing the user's run intent. Called for `scenePhase == .background`;
    /// `.inactive` is intentionally ignored (transient interruptions).
    func enterBackground() {
        isSceneActive = false
        if isFeedRunning { Task { await feed.stop() } }
    }

    /// Resumes the live transport when the app returns to the foreground, but
    /// only if the user still has the feed switched on.
    func enterForeground() {
        isSceneActive = true
        if isFeedRunning { launchFeed() }
    }

    /// Seeds the feed with the current prices and starts it.
    private func launchFeed() {
        let seed = stocks
        Task { await feed.start(symbols: seed) }
    }

    /// Toggles the feed; wired to the Start/Stop button.
    func toggleFeed() {
        isFeedRunning ? stopFeed() : startFeed()
    }

    // MARK:  -  Event Application  -

    /// Exposed at `internal` access for deterministic unit testing.
    func apply(_ event: FeedEvent) {
        switch event {
        case .statusChanged(let status):
            connectionStatus = status
        case .priceUpdate(let update):
            guard let current = stocksBySymbol[update.symbol] else { return }
            stocksBySymbol[update.symbol] = current.applying(newPrice: update.price)
        }
    }
}
