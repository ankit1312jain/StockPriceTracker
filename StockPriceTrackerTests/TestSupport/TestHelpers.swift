//
//  TestHelpers.swift
//  StockPriceTrackerTests
//
//  Shared fixtures and async polling utilities.
//

import Foundation
@testable import StockPriceTracker

// MARK:  -  Stock Fixtures  -

enum StockFixtures {
    static func stock(
        _ symbol: String,
        price: Decimal,
        previous: Decimal? = nil,
        currency: String = "USD"
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Inc.",
            about: "About \(symbol).",
            currencyCode: currency,
            price: price,
            previousPrice: previous
        )
    }
}

// MARK:  -  Async Polling  -

/// Awaits until `condition` becomes true or `timeout` elapses. Used to assert on
/// state updated by detached tasks without arbitrary fixed sleeps.
@MainActor
func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() && clock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
}
