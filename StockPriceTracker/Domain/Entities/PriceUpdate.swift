//
//  PriceUpdate.swift
//  StockPriceTracker
//
//  A single real-time price tick for one symbol.
//

import Foundation

// MARK:  -  PriceUpdate  -

/// An individual price tick received from the feed for a given symbol.
///
/// This is the `Sendable` payload that flows from the networking actor across
/// to the `@MainActor` store.
nonisolated struct PriceUpdate: Sendable, Equatable {
    let symbol: String
    let price: Decimal
    let timestamp: Date
}
