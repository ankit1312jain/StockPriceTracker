//
//  SymbolsListViewModel.swift
//  StockPriceTracker
//
//  Presentation logic for the symbols list screen.
//

import Foundation
import Observation

// MARK: - SymbolsListViewModel -

/// Drives the symbols list screen: owns the selected sort option and exposes a
/// sorted, display-ready list derived from the shared ``PriceStore``.
///
/// Because both this view model and the store are `@Observable`, reading
/// `sortedStocks` inside a view body transparently tracks the underlying store
/// properties, so live price ticks re-render the list automatically.
@MainActor
@Observable
final class SymbolsListViewModel {

    var sortOption: StockSortOption = .price

    private let store: PriceStore
    private let sortStocks = SortStocksUseCase()

    init(store: PriceStore) {
        self.store = store
    }

    // MARK: - Derived State -

    var sortedStocks: [Stock] {
        sortStocks(store.stocks, by: sortOption)
    }

    var connectionStatus: ConnectionStatus { store.connectionStatus }
    var isFeedRunning: Bool { store.isFeedRunning }
    var isLoaded: Bool { store.isLoaded }

    // MARK: - Intents -

    func toggleFeed() {
        store.toggleFeed()
    }
}
