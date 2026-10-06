//
//  StockSortOption.swift
//  StockPriceTracker
//
//  The sorting strategies offered on the symbols list screen.
//

import Foundation

// MARK:  -  StockSortOption  -

/// The two sort orders required by the symbols list screen.
nonisolated enum StockSortOption: String, CaseIterable, Identifiable, Sendable {
    case price
    case priceChange

    var id: String { rawValue }

    /// Localized, user-facing title for the segmented picker.
    var titleKey: LocalizedStringResource {
        switch self {
        case .price:       LocalizedStringResource("sort.byPrice", defaultValue: "Price")
        case .priceChange: LocalizedStringResource("sort.byPriceChange", defaultValue: "Change")
        }
    }
}
