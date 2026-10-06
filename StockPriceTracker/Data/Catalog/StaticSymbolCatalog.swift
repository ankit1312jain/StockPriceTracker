//
//  StaticSymbolCatalog.swift
//  StockPriceTracker
//
//  Bundled catalog of the 25 symbols the app tracks.
//

import Foundation

// MARK:  -  StaticSymbolCatalog  -

/// Provides the fixed set of 25 symbols (with seed prices and descriptions)
/// that the app tracks.
///
/// In a production, multi-region app this would be backed by a remote service;
/// isolating it behind ``SymbolCatalogProviding`` means that swap requires no
/// changes above the data layer.
struct StaticSymbolCatalog: SymbolCatalogProviding {

    /// Currency used for the seed catalog (US markets).
    let currencyCode: String

    init(currencyCode: String = "USD") {
        self.currencyCode = currencyCode
    }

    func loadSymbols() async throws -> [Stock] {
        Self.seed.map { entry in
            Stock(
                symbol: entry.symbol,
                name: entry.name,
                about: entry.about,
                currencyCode: currencyCode,
                price: entry.price,
                previousPrice: nil
            )
        }
    }

    // MARK:  -  Seed Data  -

    private struct Entry {
        let symbol: String
        let name: String
        let about: String
        let price: Decimal
    }

    private static let seed: [Entry] = [
        Entry(symbol: "AAPL", name: "Apple Inc.", about: "Designs and sells consumer electronics, software and services, including the iPhone, Mac and App Store.", price: 229.87),
        Entry(symbol: "MSFT", name: "Microsoft Corp.", about: "Develops software, cloud services (Azure) and hardware, and operates the LinkedIn and GitHub platforms.", price: 441.58),
        Entry(symbol: "GOOGL", name: "Alphabet Inc.", about: "Parent of Google; revenue is driven by search advertising, YouTube, Android and Google Cloud.", price: 176.30),
        Entry(symbol: "AMZN", name: "Amazon.com Inc.", about: "Global e-commerce marketplace and the leading cloud provider through Amazon Web Services.", price: 201.44),
        Entry(symbol: "NVDA", name: "NVIDIA Corp.", about: "Designs GPUs and accelerated-computing platforms powering gaming and AI data centres.", price: 138.07),
        Entry(symbol: "META", name: "Meta Platforms Inc.", about: "Operates Facebook, Instagram, WhatsApp and Messenger, and invests in augmented and virtual reality.", price: 601.29),
        Entry(symbol: "TSLA", name: "Tesla Inc.", about: "Manufactures electric vehicles, battery energy storage and solar products.", price: 352.56),
        Entry(symbol: "BRK.B", name: "Berkshire Hathaway", about: "Diversified holding company with insurance, rail, energy and consumer businesses.", price: 467.12),
        Entry(symbol: "JPM", name: "JPMorgan Chase & Co.", about: "Largest U.S. bank, spanning consumer banking, investment banking and asset management.", price: 243.78),
        Entry(symbol: "V", name: "Visa Inc.", about: "Operates the world's largest electronic payments network for card transactions.", price: 312.90),
        Entry(symbol: "JNJ", name: "Johnson & Johnson", about: "Global healthcare company producing pharmaceuticals and medical devices.", price: 152.44),
        Entry(symbol: "WMT", name: "Walmart Inc.", about: "World's largest retailer by revenue, operating hypermarkets and a growing e-commerce arm.", price: 91.35),
        Entry(symbol: "PG", name: "Procter & Gamble", about: "Consumer-goods maker of household brands across fabric, home, health and grooming care.", price: 168.22),
        Entry(symbol: "MA", name: "Mastercard Inc.", about: "Runs a global payments-processing network connecting banks, merchants and cardholders.", price: 523.61),
        Entry(symbol: "HD", name: "The Home Depot", about: "Largest home-improvement retailer, serving DIY and professional contractors.", price: 408.17),
        Entry(symbol: "XOM", name: "Exxon Mobil Corp.", about: "Integrated oil and gas company engaged in exploration, refining and chemicals.", price: 118.63),
        Entry(symbol: "BAC", name: "Bank of America", about: "Diversified financial institution offering consumer and corporate banking and wealth management.", price: 46.29),
        Entry(symbol: "KO", name: "The Coca-Cola Co.", about: "World's largest non-alcoholic beverage company with a portfolio of global drink brands.", price: 62.85),
        Entry(symbol: "PEP", name: "PepsiCo Inc.", about: "Food and beverage company behind Pepsi, Frito-Lay snacks and Quaker foods.", price: 158.04),
        Entry(symbol: "DIS", name: "The Walt Disney Co.", about: "Media and entertainment company spanning studios, streaming (Disney+) and theme parks.", price: 112.47),
        Entry(symbol: "NFLX", name: "Netflix Inc.", about: "Subscription streaming service producing and distributing film and television worldwide.", price: 897.33),
        Entry(symbol: "ADBE", name: "Adobe Inc.", about: "Creative, document and digital-experience software delivered via subscription.", price: 512.76),
        Entry(symbol: "CRM", name: "Salesforce Inc.", about: "Leading cloud customer-relationship-management (CRM) software provider.", price: 329.18),
        Entry(symbol: "INTC", name: "Intel Corp.", about: "Designs and manufactures microprocessors and semiconductor components.", price: 21.48),
        Entry(symbol: "AMD", name: "Advanced Micro Devices", about: "Designs CPUs and GPUs for computing, gaming and data-centre markets.", price: 122.91)
    ]
}
