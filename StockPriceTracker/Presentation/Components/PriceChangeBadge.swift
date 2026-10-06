//
//  PriceChangeBadge.swift
//  StockPriceTracker
//
//  Shared price-change indicator reused on the list and detail screens.
//

import SwiftUI

// MARK:  -  PriceChangeBadge  -

/// The price-change indicator shown on both the list and detail screens, so the
/// indicator is guaranteed to look and behave identically in both places.
struct PriceChangeBadge: View {

    enum Style {
        /// Arrow + percentage only (compact, for list rows).
        case compact
        /// Arrow + signed amount + percentage (for the detail screen).
        case detailed
    }

    let stock: Stock
    var style: Style = .compact

    private var direction: PriceChangeDirection { stock.direction }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.sfSymbol)
                .imageScale(.small)
            Text(text)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(style == .detailed ? .headline : .subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(direction.tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var text: String {
        let percent = PriceFormatter.signedPercent(stock.changeFraction)
        switch style {
        case .compact:
            return percent
        case .detailed:
            let amount = PriceFormatter.signedChange(stock.change, currencyCode: stock.currencyCode)
            return "\(amount) (\(percent))"
        }
    }

    private var accessibilityLabel: Text {
        let directionWord: String
        switch direction {
        case .up:        directionWord = String(localized: "a11y.up", defaultValue: "up")
        case .down:      directionWord = String(localized: "a11y.down", defaultValue: "down")
        case .unchanged: directionWord = String(localized: "a11y.unchanged", defaultValue: "unchanged")
        }
        let percent = PriceFormatter.signedPercent(stock.changeFraction)
        return Text("\(stock.symbol) \(directionWord) \(percent)")
    }
}
