//
//  FakeWebSocketClient.swift
//  StockPriceTrackerTests
//
//  In-memory WebSocket transport double for testing PriceFeedService.
//

import Foundation
@testable import StockPriceTracker

// MARK:  -  FakeWebSocketClient  -

/// A controllable ``WebSocketConnecting`` double — no real networking.
///
/// - `connect()` reports `connecting` → `connected` on the state stream.
/// - When `echoOnSend` is true, every `send` is echoed back (mimicking the
///   postman-echo server), so the feed's full produce → send → receive → decode
///   path runs.
/// - Tests can also inject frames directly via ``push(_:)`` as if they arrived
///   from the server.
actor FakeWebSocketClient: WebSocketConnecting {

    nonisolated let connectionState: AsyncStream<WebSocketConnectionState>
    private let stateContinuation: AsyncStream<WebSocketConnectionState>.Continuation

    /// Frames waiting to be delivered to `receive()`.
    private var inbox: [String] = []

    private let echoOnSend: Bool
    private(set) var sentFrames: [String] = []
    private(set) var connectCount = 0
    private(set) var disconnectCount = 0

    init(echoOnSend: Bool = true) {
        (connectionState, stateContinuation) = AsyncStream.makeStream()
        self.echoOnSend = echoOnSend
    }

    // MARK:  -  WebSocketConnecting  -

    func connect() async {
        connectCount += 1
        stateContinuation.yield(.connecting)
        stateContinuation.yield(.connected)
    }

    func send(_ text: String) async throws {
        sentFrames.append(text)
        if echoOnSend { inbox.append(text) }
    }

    func receive() async throws -> String {
        // Await the next frame. Suspending here lets `send`/`push` run and fill
        // the inbox; cancellation (e.g. on `stop()`) ends the wait cleanly.
        while true {
            try Task.checkCancellation()
            if !inbox.isEmpty { return inbox.removeFirst() }
            try await Task.sleep(for: .milliseconds(5))
        }
    }

    func disconnect() async {
        disconnectCount += 1
        stateContinuation.yield(.disconnected(code: .goingAway, reason: nil))
    }

    // MARK:  -  Driving Input  -

    /// Injects a frame as if the server had sent it.
    func push(_ text: String) {
        inbox.append(text)
    }
}
