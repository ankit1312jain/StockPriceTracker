//
//  PriceStoreTests.swift
//  StockPriceTrackerTests
//
//  Verifies the shared store loads the catalog and applies feed events.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - PriceStoreTests -

@MainActor
struct PriceStoreTests {

    @Test func loadsCatalogInOrder() async {
        let store = makeStore()
        await store.loadCatalog()
        #expect(store.isLoaded)
        #expect(store.stocks.map(\.symbol) == ["A", "B"])
    }

    @Test func statusEventUpdatesConnectionStatus() {
        let store = makeStore()
        store.apply(.statusChanged(.connecting))
        #expect(store.connectionStatus == .connecting)
        store.apply(.statusChanged(.connected))
        #expect(store.connectionStatus == .connected)
    }

    @Test func priceUpdateUpdatesPriceAndPreservesPrevious() async {
        let store = makeStore()
        await store.loadCatalog()
        store.apply(.priceUpdate(.init(symbol: "A", price: 120, timestamp: .now)))
        #expect(store.stock(for: "A")?.price == 120)
        #expect(store.stock(for: "A")?.previousPrice == 100)
        #expect(store.stock(for: "A")?.direction == .up)
    }

    @Test func unknownSymbolIsIgnored() async {
        let store = makeStore()
        await store.loadCatalog()
        store.apply(.priceUpdate(.init(symbol: "ZZZ", price: 1, timestamp: .now)))
        #expect(store.stock(for: "ZZZ") == nil)
        #expect(store.stock(for: "A")?.price == 100)
    }

    @Test func startAndStopFeedToggleStateAndInvokeFeed() async {
        let feed = MockPriceFeed()
        let store = PriceStore(catalog: MockSymbolCatalog(stocks: [f("A", 100)]), feed: feed)
        await store.loadCatalog()

        store.startFeed()
        #expect(store.isFeedRunning)
        await waitUntil { feed.startCallCount == 1 }
        #expect(feed.startCallCount == 1)

        // Guarded: starting again while running does nothing.
        store.startFeed()
        #expect(feed.startCallCount == 1)

        store.stopFeed()
        #expect(!store.isFeedRunning)
        await waitUntil { feed.stopCallCount == 1 }
        #expect(feed.stopCallCount == 1)
    }

    @Test func observesFeedEventsEndToEnd() async {
        let feed = MockPriceFeed()
        let store = PriceStore(catalog: MockSymbolCatalog(stocks: [f("A", 100)]), feed: feed)

        let task = Task { await store.activate() }
        await waitUntil { store.isLoaded }

        feed.emit(.statusChanged(.connected))
        feed.emit(.priceUpdate(.init(symbol: "A", price: 150, timestamp: .now)))
        await waitUntil { store.stock(for: "A")?.price == 150 }

        #expect(store.connectionStatus == .connected)
        #expect(store.stock(for: "A")?.price == 150)

        task.cancel()
        feed.finish()
    }

    // MARK: - Helpers -

    private func makeStore() -> PriceStore {
        PriceStore(catalog: MockSymbolCatalog(stocks: [f("A", 100), f("B", 200)]), feed: MockPriceFeed())
    }

    private func f(_ symbol: String, _ price: Decimal) -> Stock {
        StockFixtures.stock(symbol, price: price)
    }
}
