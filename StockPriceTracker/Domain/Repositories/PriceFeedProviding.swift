//
//  PriceFeedProviding.swift
//  StockPriceTracker
//
//  Port for the real-time price feed.
//

import Foundation

// MARK:  -  PriceFeedProviding  -

/// Abstraction over the real-time price feed.
///
/// Exposes a single `events` stream (status + ticks) so consumers observe one
/// source of truth. Concrete implementations own the transport (WebSocket);
/// the protocol keeps the presentation layer testable with in-memory mocks.
protocol PriceFeedProviding: Sendable {

    /// A long-lived stream of feed events. Valid for the lifetime of the feed;
    /// values are produced only between `start(symbols:)` and `stop()`.
    var events: AsyncStream<FeedEvent> { get }

    /// Begins producing price updates for the given symbols.
    /// - Parameter symbols: seed symbols (used for base price & currency).
    func start(symbols: [Stock]) async

    /// Stops the feed and tears down the underlying connection.
    func stop() async
}
