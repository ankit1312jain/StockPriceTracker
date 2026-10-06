//
//  MockSymbolCatalog.swift
//  StockPriceTrackerTests
//
//  Fixed, in-memory symbol catalog for tests.
//

import Foundation
@testable import StockPriceTracker

// MARK:  -  MockSymbolCatalog  -

struct MockSymbolCatalog: SymbolCatalogProviding {
    let stocks: [Stock]
    func loadSymbols() async throws -> [Stock] { stocks }
}
