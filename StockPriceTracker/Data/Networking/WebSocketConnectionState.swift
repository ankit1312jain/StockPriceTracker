//
//  WebSocketConnectionState.swift
//  StockPriceTracker
//
//  Transport-level connection state, reported by the WebSocket delegate.
//

import Foundation

// MARK:  -  WebSocketConnectionState  -

/// The real connection state of the underlying WebSocket transport.
///
/// Unlike the optimistic "connected the moment we resume" approach, these cases
/// are driven by `URLSessionWebSocketDelegate` callbacks, so they reflect the
/// actual handshake, close, and failure events. `PriceFeedService` maps them to
/// the domain ``ConnectionStatus``.
nonisolated enum WebSocketConnectionState: Sendable {
    /// `connect()` was requested; the handshake is in flight.
    case connecting
    /// The socket handshake completed (`didOpenWithProtocol`).
    case connected
    /// The socket closed cleanly with a close code (`didCloseWith`).
    case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    /// The underlying task completed with an error (`didCompleteWithError`).
    case failed(message: String)
}
