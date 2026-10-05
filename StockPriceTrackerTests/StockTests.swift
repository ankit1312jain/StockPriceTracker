//
//  StockTests.swift
//  StockPriceTrackerTests
//
//  Verifies the derived price-change logic on the core domain entity.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - StockTests -

struct StockTests {

    @Test func risingPriceReportsUpward() {
        let stock = StockFixtures.stock("X", price: 110, previous: 100)
        #expect(stock.direction == .up)
        #expect(stock.change == 10)
        #expect(stock.changeFraction == Decimal(string: "0.1"))
    }

    @Test func fallingPriceReportsDownward() {
        let stock = StockFixtures.stock("X", price: 90, previous: 100)
        #expect(stock.direction == .down)
        #expect(stock.change == -10)
    }

    @Test func equalPriceIsUnchanged() {
        let stock = StockFixtures.stock("X", price: 100, previous: 100)
        #expect(stock.direction == .unchanged)
        #expect(stock.change == 0)
        #expect(stock.changeFraction == 0)
    }

    @Test func missingBaselineIsUnchanged() {
        let stock = StockFixtures.stock("X", price: 100, previous: nil)
        #expect(stock.direction == .unchanged)
        #expect(stock.change == 0)
        #expect(stock.changeFraction == 0)
    }

    @Test func applyingNewPricePreservesPreviousValue() {
        let updated = StockFixtures.stock("X", price: 100).applying(newPrice: 120)
        #expect(updated.price == 120)
        #expect(updated.previousPrice == 100)
        #expect(updated.direction == .up)
    }
}
