//
//  PriceFormatter.swift
//  StockPriceTracker
//
//  Locale-aware formatting of prices and price changes.
//

import Foundation

// MARK: - PriceFormatter -

/// Centralised, locale-aware formatting so both screens render prices
/// identically and correctly for the user's region (the "multi-regional"
/// requirement). All styles honour `Locale.current` by default.
enum PriceFormatter {

    /// Formats an absolute price, e.g. `"$229.87"` / `"229,87 €"`.
    static func price(_ value: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        value.formatted(.currency(code: currencyCode).locale(locale))
    }

    /// Formats a signed monetary change, e.g. `"+$1.20"` / `"-$0.75"`.
    static func signedChange(_ value: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        value.formatted(
            .currency(code: currencyCode)
            .sign(strategy: .always())
            .locale(locale)
        )
    }

    /// Formats a signed percentage from a fraction, e.g. `0.0123` -> `"+1.23%"`.
    static func signedPercent(_ fraction: Decimal, locale: Locale = .current) -> String {
        fraction.formatted(
            .percent
            .precision(.fractionLength(2))
            .sign(strategy: .always())
            .locale(locale)
        )
    }
}
