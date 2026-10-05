//
//  PriceStore.swift
//  StockPriceTracker
//
//  Single source of truth for live prices, shared across every screen.
//

import Foundation
import Observation

// MARK: - PriceStore -

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
    private(set) var isFeedRunning = false

    private let catalog: SymbolCatalogProviding
    private let feed: PriceFeedProviding

    init(catalog: SymbolCatalogProviding, feed: PriceFeedProviding) {
        self.catalog = catalog
        self.feed = feed
    }

    // MARK: - Derived Access -

    /// All stocks in catalog order.
    var stocks: [Stock] {
        orderedSymbols.compactMap { stocksBySymbol[$0] }
    }

    /// Looks up a single stock by symbol (used by the detail screen).
    func stock(for symbol: String) -> Stock? {
        stocksBySymbol[symbol]
    }

    // MARK: - Lifecycle -

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

    // MARK: - Feed Control -

    /// Starts the price feed (connects and begins streaming updates).
    func startFeed() {
        guard !isFeedRunning else { return }
        isFeedRunning = true
        let seed = stocks
        Task { await feed.start(symbols: seed) }
    }

    /// Stops the price feed and disconnects.
    func stopFeed() {
        guard isFeedRunning else { return }
        isFeedRunning = false
        Task { await feed.stop() }
    }

    /// Toggles the feed; wired to the Start/Stop button.
    func toggleFeed() {
        isFeedRunning ? stopFeed() : startFeed()
    }

    // MARK: - Event Application -

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
