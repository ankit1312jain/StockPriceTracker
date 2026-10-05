//
//  AppContainer.swift
//  StockPriceTracker
//
//  Composition root — wires Data -> Domain -> Presentation dependencies.
//

import Foundation

// MARK: - AppContainer -

/// The single composition root where concrete dependencies are assembled and
/// injected. Views and view models depend only on protocols, so swapping an
/// implementation (e.g. a remote catalog, or a different transport per region)
/// happens here and nowhere else.
@MainActor
struct AppContainer {

    let configuration: AppConfiguration

    init(configuration: AppConfiguration = .default) {
        self.configuration = configuration
    }

    /// Builds the shared ``PriceStore`` with production dependencies.
    func makeStore() -> PriceStore {
        let catalog = StaticSymbolCatalog(currencyCode: configuration.currencyCode)
        let client = URLSessionWebSocketClient(url: configuration.feedURL)
        let feed = PriceFeedService(client: client)
        return PriceStore(catalog: catalog, feed: feed)
    }
}
