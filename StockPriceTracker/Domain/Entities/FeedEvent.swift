//
//  FeedEvent.swift
//  StockPriceTracker
//
//  Events emitted by the price feed over time.
//

import Foundation

// MARK: - FeedEvent -

/// A time-ordered event produced by a ``PriceFeedProviding`` implementation.
///
/// Modelling status and data as a single stream of events means the store has
/// exactly one place to observe, which keeps real-time updates consistent
/// across every screen.
nonisolated enum FeedEvent: Sendable, Equatable {
    /// The connection lifecycle changed.
    case statusChanged(ConnectionStatus)
    /// A new price tick arrived for a symbol.
    case priceUpdate(PriceUpdate)
}
