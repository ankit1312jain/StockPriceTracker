//
//  SymbolDetailView.swift
//  StockPriceTracker
//
//  Detail screen for a single symbol; prices update live in sync with the list.
//

import SwiftUI

// MARK:  -  SymbolDetailView  -

/// Shows the selected symbol's title, live price (with the *same* change badge
/// used in the list) and a description.
///
/// It reads the stock from the shared ``PriceStore`` on every render, so when a
/// tick arrives this screen updates in real time, in lock-step with the list.
struct SymbolDetailView: View {

    let symbol: String

    @Environment(PriceStore.self) private var store

    var body: some View {
        Group {
            if let stock = store.stock(for: symbol) {
                content(for: stock)
            } else {
                ContentUnavailableView(
                    "Symbol Unavailable",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("No data is available for \(symbol).")
                )
            }
        }
        .navigationTitle(symbol)
    }

    // MARK:  -  Content  -

    private func content(for stock: Stock) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                priceHeader(for: stock)
                Divider()
                descriptionSection(for: stock)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func priceHeader(for stock: Stock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stock.name)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(PriceFormatter.price(stock.price, currencyCode: stock.currencyCode))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .animatedNumericText()
            PriceChangeBadge(stock: stock, style: .detailed)
        }
    }

    private func descriptionSection(for stock: Stock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(stock.about)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
