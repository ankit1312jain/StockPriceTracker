//
//  URLSessionWebSocketClient.swift
//  StockPriceTracker
//
//  Concrete WebSocket transport backed by URLSessionWebSocketTask.
//

import Foundation

// MARK:  -  URLSessionWebSocketClient  -

/// A thread-safe WebSocket client built on `URLSessionWebSocketTask`.
///
/// Implemented as an `actor` so all mutable task state is isolated — the
/// natural fit under Swift 6 strict concurrency. The endpoint is injected,
/// which supports a config-driven, multi-region deployment.
actor URLSessionWebSocketClient: WebSocketConnecting {

    nonisolated let connectionState: AsyncStream<WebSocketConnectionState>
    private let stateContinuation: AsyncStream<WebSocketConnectionState>.Continuation

    private let url: URL
    private let session: URLSession
    private let delegate: Delegate
    private var task: URLSessionWebSocketTask?

    init(url: URL, configuration: URLSessionConfiguration = .default) {
        self.url = url
        (connectionState, stateContinuation) = AsyncStream.makeStream()
        let delegate = Delegate(continuation: stateContinuation)
        self.delegate = delegate
        self.session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    // MARK:  -  WebSocketConnecting  -

    func connect() async {
        // `connecting` is client intent — the OS can't report it, so we emit it
        // here; `connected` / `disconnected` / `failed` come from the delegate.
        stateContinuation.yield(.connecting)
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

    // MARK:  -  Delegate  -

    /// Bridges `URLSession` delegate callbacks (invoked on the session's
    /// delegate queue) into the actor's connection-state stream. Mirrors the
    /// Android client's `WebSocketListener`.
    ///
    /// `@unchecked Sendable` is sound here: the only stored state is the stream
    /// continuation (itself `Sendable`), and the callbacks only call `yield`.
    private final class Delegate: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {

        private let continuation: AsyncStream<WebSocketConnectionState>.Continuation

        init(continuation: AsyncStream<WebSocketConnectionState>.Continuation) {
            self.continuation = continuation
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didOpenWithProtocol protocol: String?
        ) {
            continuation.yield(.connected)
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
            reason: Data?
        ) {
            let text = reason.flatMap { String(data: $0, encoding: .utf8) }
            continuation.yield(.disconnected(code: closeCode, reason: text))
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didCompleteWithError error: Error?
        ) {
            if let error {
                continuation.yield(.failed(message: error.localizedDescription))
            }
        }
    }
}

// MARK:  -  WebSocketError  -

enum WebSocketError: Error, Equatable {
    case notConnected
    case unsupportedMessage
}
