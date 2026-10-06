//
//  PriceChangeDirection+UI.swift
//  StockPriceTracker
//
//  Presentation-only mapping of the domain direction to SF Symbols & colours.
//

import SwiftUI

// MARK:  -  PriceChangeDirection UI  -

extension PriceChangeDirection {

    /// SF Symbol used to convey direction *without relying on colour alone*
    /// (accessibility for colour-blind users).
    var sfSymbol: String {
        switch self {
        case .up:        "arrow.up.right"
        case .down:      "arrow.down.right"
        case .unchanged: "minus"
        }
    }

    /// Tint used for the badge and price delta.
    var tint: Color {
        switch self {
        case .up:        .green
        case .down:      .red
        case .unchanged: .secondary
        }
    }
}
