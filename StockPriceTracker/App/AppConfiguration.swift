//
//  AppConfiguration.swift
//  StockPriceTracker
//
//  Environment / region configuration resolved at app launch.
//

import Foundation

// MARK:  -  AppConfiguration  -

/// Launch-time configuration. Keeping the feed endpoint and currency here
/// (rather than hard-coded in the networking layer) is what lets a build target
/// a different region/environment — the backbone of a multi-region rollout.
struct AppConfiguration: Sendable {

    let feedURL: URL
    let currencyCode: String

    /// Default configuration pointing at the assessment's echo endpoint.
    static let `default` = AppConfiguration(
        // Compile-time constant, known-valid literal.
        feedURL: URL(string: "wss://ws.postman-echo.com/raw")!,
        currencyCode: "USD"
    )
}
