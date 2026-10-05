//
//  Stock.swift
//  StockPriceTracker
//
//  Core domain value type representing a tradable symbol and its latest price.
//

import Foundation

// MARK: - Stock -

/// A single tradable symbol together with its most recent price information.
///
/// `Stock` is an immutable-by-default value type (`Sendable`) so it can cross
/// concurrency boundaries freely under Swift 6 strict concurrency. Price change
/// information is *derived* from `price` and `previousPrice` rather than stored,
/// which keeps the single source of truth unambiguous.
nonisolated struct Stock: Identifiable, Sendable, Equatable {

    /// The ticker symbol, e.g. `"AAPL"`. Also serves as the stable identity.
    let symbol: String

    /// Human-readable company name, e.g. `"Apple Inc."`.
    let name: String

    /// A short description of the company, shown on the detail screen.
    let about: String

    /// ISO 4217 currency code used to format `price` for the user's region.
    let currencyCode: String

    /// The latest known price.
    var price: Decimal

    /// The price immediately preceding `price`, if any update has occurred yet.
    var previousPrice: Decimal?

    var id: String { symbol }

    // MARK: - Derived Price Change -

    /// Absolute change between the previous and current price.
    var change: Decimal {
        guard let previousPrice else { return 0 }
        return price - previousPrice
    }

    /// Fractional change (e.g. `0.0123` for +1.23%), suitable for
    /// `FormatStyle.Percent`. Returns `0` when there is no valid baseline.
    var changeFraction: Decimal {
        guard let previousPrice, previousPrice != 0 else { return 0 }
        return change / previousPrice
    }

    /// Whether the latest update moved the price up, down, or not at all.
    var direction: PriceChangeDirection {
        guard previousPrice != nil else { return .unchanged }
        if change > 0 { return .up }
        if change < 0 { return .down }
        return .unchanged
    }
}

// MARK: - Mutation Helpers -

extension Stock {
    /// Returns a copy with `price` advanced to `newPrice`, preserving the old
    /// value as `previousPrice` so change indicators can be derived.
    nonisolated func applying(newPrice: Decimal) -> Stock {
        var copy = self
        copy.previousPrice = price
        copy.price = newPrice
        return copy
    }
}
