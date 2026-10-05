//
//  SymbolsListViewModelTests.swift
//  StockPriceTrackerTests
//
//  Verifies sorting selection and feed control on the list view model.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - SymbolsListViewModelTests -

@MainActor
struct SymbolsListViewModelTests {

    @Test func sortsByPriceDescending() async {
        let store = await loadedStore([f("A", 50), f("B", 200), f("C", 100)])
        let viewModel = SymbolsListViewModel(store: store)
        viewModel.sortOption = .price
        #expect(viewModel.sortedStocks.map(\.symbol) == ["B", "C", "A"])
    }

    @Test func sortsByPriceChangeDescending() async {
        let store = await loadedStore([f("A", 100), f("B", 100), f("C", 100)])
        store.apply(.priceUpdate(.init(symbol: "A", price: 110, timestamp: .now))) // +10%
        store.apply(.priceUpdate(.init(symbol: "B", price: 90, timestamp: .now)))  // -10%

        let viewModel = SymbolsListViewModel(store: store)
        viewModel.sortOption = .priceChange
        #expect(viewModel.sortedStocks.map(\.symbol) == ["A", "C", "B"])
    }

    @Test func toggleFeedFlipsRunningStateAndDrivesStore() async {
        let feed = MockPriceFeed()
        let store = PriceStore(catalog: MockSymbolCatalog(stocks: [f("A", 100)]), feed: feed)
        await store.loadCatalog()
        let viewModel = SymbolsListViewModel(store: store)

        #expect(!viewModel.isFeedRunning)

        viewModel.toggleFeed()
        #expect(viewModel.isFeedRunning)
        await waitUntil { feed.startCallCount == 1 }
        #expect(feed.startCallCount == 1)

        viewModel.toggleFeed()
        #expect(!viewModel.isFeedRunning)
        await waitUntil { feed.stopCallCount == 1 }
        #expect(feed.stopCallCount == 1)
    }

    // MARK: - Helpers -

    private func loadedStore(_ stocks: [Stock]) async -> PriceStore {
        let store = PriceStore(catalog: MockSymbolCatalog(stocks: stocks), feed: MockPriceFeed())
        await store.loadCatalog()
        return store
    }

    private func f(_ symbol: String, _ price: Decimal) -> Stock {
        StockFixtures.stock(symbol, price: price)
    }
}
