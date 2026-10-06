//
//  RandomPriceGenerator.swift
//  StockPriceTracker
//
//  Produces simulated price ticks as a bounded random walk.
//

import Foundation

// MARK:  -  RandomPriceGenerator  -

/// Generates the next price for a symbol as a small, bounded random walk from a
/// base value.
///
/// The random source is injected (`inout some RandomNumberGenerator`) so tests
/// can supply a seeded generator for fully deterministic output.
///
/// Marked `nonisolated` so it can be used from the off-main feed `actor` under
/// the project's `MainActor`-by-default isolation.
nonisolated struct RandomPriceGenerator: Sendable {

    /// Maximum fractional move per tick (e.g. `0.02` == ±2%).
    let maxMovePercent: Double

    /// Floor below which a price is never allowed to fall.
    let minimumPrice: Decimal

    init(maxMovePercent: Double = 0.02, minimumPrice: Decimal = 0.01) {
        self.maxMovePercent = maxMovePercent
        self.minimumPrice = minimumPrice
    }

    /// Returns the next price derived from `base`, rounded to 2 decimal places.
    func nextPrice(base: Decimal, using rng: inout some RandomNumberGenerator) -> Decimal {
        let movePercent = Double.random(in: -maxMovePercent...maxMovePercent, using: &rng)
        let baseValue = NSDecimalNumber(decimal: base).doubleValue
        let nextValue = baseValue * (1 + movePercent)
        let next = Decimal(nextValue).rounded(2)
        return max(next, minimumPrice)
    }
}
