//
//  ConnectionStatus.swift
//  StockPriceTracker
//
//  Domain representation of the live price-feed connection state.
//

import Foundation

// MARK: - ConnectionStatus -

/// The lifecycle state of the real-time price feed connection.
///
/// `connecting` is surfaced so the UI can distinguish an in-flight handshake
/// (and auto-reconnect attempts) from a fully disconnected state.
nonisolated enum ConnectionStatus: Sendable, Equatable {
    case disconnected
    case connecting
    case connected

    /// `true` only when the feed is fully established.
    var isConnected: Bool { self == .connected }
}
