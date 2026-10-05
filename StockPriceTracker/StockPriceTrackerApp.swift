//
//  StockPriceTrackerApp.swift
//  StockPriceTracker
//
//  Created by Ankit Jain MAC on 05/10/2026.
//

import SwiftUI

// MARK: - StockPriceTrackerApp -

@main
struct StockPriceTrackerApp: App {

    /// The shared source of truth, created once from the composition root and
    /// injected into the environment so every screen observes the same prices.
    @State private var store: PriceStore

    init() {
        let container = AppContainer()
        _store = State(initialValue: container.makeStore())
    }

    var body: some Scene {
        WindowGroup {
            SymbolsListView(store: store)
                .environment(store)
                .task {
                    // Loads the catalog and starts observing feed events for
                    // the lifetime of the scene.
                    await store.activate()
                }
        }
    }
}
