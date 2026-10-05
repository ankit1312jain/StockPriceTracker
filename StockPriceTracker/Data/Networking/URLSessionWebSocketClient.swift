//
//  URLSessionWebSocketClient.swift
//  StockPriceTracker
//
//  Concrete WebSocket transport backed by URLSessionWebSocketTask.
//

import Foundation

// MARK: - URLSessionWebSocketClient -

/// A thread-safe WebSocket client built on `URLSessionWebSocketTask`.
///
/// Implemented as an `actor` so all mutable task state is isolated — the
/// natural fit under Swift 6 strict concurrency. The endpoint is injected,
/// which supports a config-driven, multi-region deployment.
actor URLSessionWebSocketClient: WebSocketConnecting {

    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    init(url: URL, session: URLSession = URLSession(configuration: .default)) {
        self.url = url
        self.session = session
    }

    // MARK: - WebSocketConnecting -

    func connect() async {
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
    }

    func send(_ text: String) async throws {
        guard let task else { throw WebSocketError.notConnected }
        try await task.send(.string(text))
    }

    func receive() async throws -> String {
        guard let task else { throw WebSocketError.notConnected }
        let message = try await task.receive()
        switch message {
        case .string(let text):
            return text
        case .data(let data):
            return String(decoding: data, as: UTF8.self)
        @unknown default:
            throw WebSocketError.unsupportedMessage
        }
    }

    func disconnect() async {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
}

// MARK: - WebSocketError -

enum WebSocketError: Error, Equatable {
    case notConnected
    case unsupportedMessage
}
