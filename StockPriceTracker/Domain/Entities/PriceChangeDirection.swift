//
//  PriceChangeDirection.swift
//  StockPriceTracker
//
//  Domain entity describing how a price moved relative to its previous value.
//

import Foundation

// MARK:  -  PriceChangeDirection  -

/// The direction a price moved between two consecutive updates.
///
/// Kept in the Domain layer and free of any UI concerns (colours, glyphs).
/// Presentation maps these cases to SF Symbols / colours so the domain stays
/// portable across platforms and regions.
nonisolated enum PriceChangeDirection: Sendable, Equatable {
    case up
    case down
    case unchanged
}
