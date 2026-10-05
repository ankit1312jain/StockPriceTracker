//
//  SymbolRowView.swift
//  StockPriceTracker
//
//  A single row in the symbols list: name, price and change indicator.
//

import SwiftUI

// MARK: - SymbolRowView -

/// One row of the symbols list showing the symbol, company name, current price
/// and the shared price-change badge.
struct SymbolRowView: View {

    let stock: Stock

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatter.price(stock.price, currencyCode: stock.currencyCode))
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                PriceChangeBadge(stock: stock, style: .compact)
            }
        }
        .padding(.vertical, 4)
    }
}
