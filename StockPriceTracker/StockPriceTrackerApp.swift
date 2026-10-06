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

    @Environment(\.scenePhase) private var scenePhase

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
                .onChange(of: scenePhase) { _, phase in
                    // Suspend the live transport in the background and resume it
                    // on return. `.inactive` is ignored so transient
                    // interruptions (Control Center, app switcher) don't drop
                    // the feed.
                    switch phase {
                    case .background:
                        store.enterBackground()
                    case .active:
                        store.enterForeground()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}
