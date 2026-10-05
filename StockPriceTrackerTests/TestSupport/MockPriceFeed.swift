//
//  MockPriceFeed.swift
//  StockPriceTrackerTests
//
//  In-memory price feed double driven manually by tests (zero networking).
//

import Foundation
@testable import StockPriceTracker

// MARK: - MockPriceFeed -

/// A controllable ``PriceFeedProviding`` double. Tests push events via `emit`
/// and inspect how `start`/`stop` were called. Thread-safe via a lock because
/// `start`/`stop` are invoked from detached tasks.
final class MockPriceFeed: PriceFeedProviding, @unchecked Sendable {

    nonisolated let events: AsyncStream<FeedEvent>
    private let continuation: AsyncStream<FeedEvent>.Continuation

    private let lock = NSLock()
    private var _startCallCount = 0
    private var _stopCallCount = 0
    private var _startedSymbols: [Stock] = []

    init() {
        (events, continuation) = AsyncStream.makeStream(of: FeedEvent.self)
    }

    // MARK: - Inspection -

    var startCallCount: Int { lock.withLock { _startCallCount } }
    var stopCallCount: Int { lock.withLock { _stopCallCount } }
    var startedSymbols: [Stock] { lock.withLock { _startedSymbols } }

    // MARK: - PriceFeedProviding -

    func start(symbols: [Stock]) async {
        lock.withLock {
            _startCallCount += 1
            _startedSymbols = symbols
        }
    }

    func stop() async {
        lock.withLock { _stopCallCount += 1 }
    }

    // MARK: - Driving Events -

    func emit(_ event: FeedEvent) { continuation.yield(event) }
    func finish() { continuation.finish() }
}
