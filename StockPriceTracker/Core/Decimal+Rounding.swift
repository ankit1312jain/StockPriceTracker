//
//  Decimal+Rounding.swift
//  StockPriceTracker
//
//  Small cross-cutting helper for rounding monetary `Decimal` values.
//

import Foundation

// MARK: - Decimal Rounding -

extension Decimal {
    /// Returns the value rounded to `scale` fractional digits.
    ///
    /// Uses `NSDecimalRound` to avoid the precision pitfalls of going through
    /// `Double`, which matters for currency values.
    nonisolated func rounded(_ scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}
