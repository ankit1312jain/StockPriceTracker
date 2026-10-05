//
//  SortStocksUseCaseTests.swift
//  StockPriceTrackerTests
//
//  Verifies the ordering rules for the symbols list.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - SortStocksUseCaseTests -

struct SortStocksUseCaseTests {

    private let sut = SortStocksUseCase()

    @Test func sortsByPriceDescending() {
        let stocks = [f("A", 50), f("B", 200), f("C", 100)]
        #expect(sut(stocks, by: .price).map(\.symbol) == ["B", "C", "A"])
    }

    @Test func sortsByPriceChangeDescending() {
        let stocks = [f("A", 110, 100), f("B", 90, 100), f("C", 100, 100)]
        #expect(sut(stocks, by: .priceChange).map(\.symbol) == ["A", "C", "B"])
    }

    @Test func tieBreaksBySymbolAscending() {
        let stocks = [f("C", 100), f("A", 100), f("B", 100)]
        #expect(sut(stocks, by: .price).map(\.symbol) == ["A", "B", "C"])
    }

    @Test func emptyInputReturnsEmpty() {
        #expect(sut([], by: .price).isEmpty)
        #expect(sut([], by: .priceChange).isEmpty)
    }

    private func f(_ symbol: String, _ price: Decimal, _ previous: Decimal? = nil) -> Stock {
        StockFixtures.stock(symbol, price: price, previous: previous)
    }
}
