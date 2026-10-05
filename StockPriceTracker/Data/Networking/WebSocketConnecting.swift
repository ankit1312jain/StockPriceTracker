//
//  WebSocketConnecting.swift
//  StockPriceTracker
//
//  Transport abstraction over a text-based WebSocket connection.
//

import Foundation

// MARK: - WebSocketConnecting -

/// A minimal, transport-level abstraction over a text WebSocket.
///
/// Keeping this behind a protocol lets the feed service be driven by an
/// in-memory fake in tests, with zero real networking. The concrete type is
/// ``URLSessionWebSocketClient``.
protocol WebSocketConnecting: Sendable {
    /// Establishes the connection (resumes the underlying task).
    func connect() async

    /// Sends a UTF-8 text frame.
    func send(_ text: String) async throws

    /// Awaits the next text frame. Throws if the connection drops.
    func receive() async throws -> String

    /// Closes the connection.
    func disconnect() async
}
