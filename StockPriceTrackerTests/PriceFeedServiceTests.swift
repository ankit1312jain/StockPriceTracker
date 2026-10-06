//
//  PriceFeedServiceTests.swift
//  StockPriceTrackerTests
//
//  Exercises the real PriceFeedService over an in-memory fake transport.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK:  -  PriceFeedServiceTests  -

@MainActor
struct PriceFeedServiceTests {

    @Test func connectsAndStreamsEchoedPriceUpdates() async {
        let socket = FakeWebSocketClient(echoOnSend: true)
        let feed = PriceFeedService(
            client: socket,
            tickInterval: 0.0...0.0,   // fire a tick immediately
            maxReconnectDelay: 0.1
        )
        let recorder = EventRecorder()
        let consumer = Task { for await event in feed.events { await recorder.add(event) } }

        await feed.start(symbols: [StockFixtures.stock("AAPL", price: 100)])

        await poll {
            let connected = await recorder.sawConnected
            let update = await recorder.sawUpdate(for: "AAPL")
            return connected && update
        }

        #expect(await recorder.sawConnected)
        #expect(await recorder.sawUpdate(for: "AAPL"))

        await feed.stop()
        consumer.cancel()
    }

    @Test func decodesServerPushedFrame() async throws {
        let socket = FakeWebSocketClient(echoOnSend: false)
        let feed = PriceFeedService(
            client: socket,
            tickInterval: 10.0...10.0  // keep the producer idle during the test
        )
        let recorder = EventRecorder()
        let consumer = Task { for await event in feed.events { await recorder.add(event) } }

        await feed.start(symbols: [StockFixtures.stock("MSFT", price: 200)])
        await poll { await recorder.sawConnected }

        // Inject a frame exactly as the server would echo it.
        let json = try PriceUpdateCodec().encode(
            PriceUpdate(symbol: "MSFT", price: 250, timestamp: Date())
        )
        await socket.push(json)

        await poll { await recorder.sawUpdate(for: "MSFT") }

        let update = await recorder.latestUpdate(for: "MSFT")
        #expect(update?.price == 250)

        await feed.stop()
        consumer.cancel()
    }

    @Test func stopDisconnectsTheTransport() async {
        let socket = FakeWebSocketClient(echoOnSend: false)
        let feed = PriceFeedService(client: socket, tickInterval: 1.0...1.0)
        let recorder = EventRecorder()
        let consumer = Task { for await event in feed.events { await recorder.add(event) } }

        await feed.start(symbols: [StockFixtures.stock("AAPL", price: 100)])
        await poll { await recorder.sawConnected }

        await feed.stop()
        await poll { await socket.disconnectCount >= 1 }

        #expect(await socket.disconnectCount >= 1)
        #expect(await recorder.sawDisconnected)
        consumer.cancel()
    }
}

// MARK:  -  Test Support  -

/// Thread-safe collector for the feed's event stream.
private actor EventRecorder {
    private var events: [FeedEvent] = []

    func add(_ event: FeedEvent) { events.append(event) }

    var sawConnected: Bool {
        events.contains { if case .statusChanged(.connected) = $0 { true } else { false } }
    }

    var sawDisconnected: Bool {
        events.contains { if case .statusChanged(.disconnected) = $0 { true } else { false } }
    }

    func sawUpdate(for symbol: String) -> Bool {
        latestUpdate(for: symbol) != nil
    }

    func latestUpdate(for symbol: String) -> PriceUpdate? {
        events.reversed().compactMap { event -> PriceUpdate? in
            if case .priceUpdate(let update) = event, update.symbol == symbol { return update }
            return nil
        }.first
    }
}

/// Polls `condition` until it is true or `timeout` elapses (no fixed sleeps).
private func poll(timeout: Duration = .seconds(3), _ condition: () async -> Bool) async {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if await condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
