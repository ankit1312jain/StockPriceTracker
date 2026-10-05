//
//  SortStocksUseCase.swift
//  StockPriceTracker
//
//  Pure business rule for ordering stocks by the selected sort option.
//

import Foundation

// MARK: - SortStocksUseCase -

/// Encapsulates the ordering rules for the symbols list.
///
/// Implemented as a pure, `Sendable` value with no dependencies so it is
/// trivially unit-testable and reusable. Sorting is **stable with an explicit
/// tie-break** on `symbol`, which keeps row order deterministic as prices tick.
nonisolated struct SortStocksUseCase: Sendable {

    func callAsFunction(_ stocks: [Stock], by option: StockSortOption) -> [Stock] {
        stocks.sorted { lhs, rhs in
            switch option {
            case .price:
                if lhs.price != rhs.price { return lhs.price > rhs.price }
            case .priceChange:
                if lhs.changeFraction != rhs.changeFraction {
                    return lhs.changeFraction > rhs.changeFraction
                }
            }
            // Deterministic tie-break so equal values keep a stable order.
            return lhs.symbol < rhs.symbol
        }
    }
}
