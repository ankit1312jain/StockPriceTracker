//
//  SymbolCatalogProviding.swift
//  StockPriceTracker
//
//  Port for loading the catalog of tradable symbols.
//

import Foundation

// MARK: - SymbolCatalogProviding -

/// Supplies the set of symbols the app tracks, along with seed metadata
/// (name, description, initial price, currency).
///
/// Declared `async throws` so a future implementation can fetch the catalog
/// from a remote, region-specific service without changing call sites.
protocol SymbolCatalogProviding: Sendable {
    func loadSymbols() async throws -> [Stock]
}
