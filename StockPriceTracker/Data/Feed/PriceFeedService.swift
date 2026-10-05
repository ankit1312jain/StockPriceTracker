//
//  PriceFeedService.swift
//  StockPriceTracker
//
//  Real-time price feed that drives the WebSocket echo endpoint.
//

import Foundation

// MARK: - PriceFeedService -

/// Drives the live price feed over a ``WebSocketConnecting`` transport.
///
/// Responsibilities:
/// - periodically generate a random price tick and **send** it to the echo
///   server (producer loop),
/// - **receive** the echoed JSON and surface it as a `.priceUpdate` event
///   (receiver loop),
/// - manage connection lifecycle and **auto-reconnect with backoff** while the
///   feed is meant to be running.
///
/// Isolated as an `actor`; all cross-boundary payloads are `Sendable`.
actor PriceFeedService: PriceFeedProviding {

    nonisolated let events: AsyncStream<FeedEvent>
    private let continuation: AsyncStream<FeedEvent>.Continuation

    private let client: WebSocketConnecting
    private let generator: RandomPriceGenerator
    private let codec: PriceUpdateCodec
    private let tickInterval: ClosedRange<Double>
    private let maxReconnectDelay: Double

    private var basePrices: [String: Decimal] = [:]
    private var symbols: [String] = []
    private var supervisor: Task<Void, Never>?
    private var isRunning = false

    init(
        client: WebSocketConnecting,
        generator: RandomPriceGenerator = RandomPriceGenerator(),
        codec: PriceUpdateCodec = PriceUpdateCodec(),
        tickInterval: ClosedRange<Double> = 0.3...0.8,
        maxReconnectDelay: Double = 10
    ) {
        self.client = client
        self.generator = generator
        self.codec = codec
        self.tickInterval = tickInterval
        self.maxReconnectDelay = maxReconnectDelay
        (events, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1024))
    }

    // MARK: - PriceFeedProviding -

    func start(symbols: [Stock]) {
        guard !isRunning else { return }
        isRunning = true
        self.symbols = symbols.map(\.symbol)
        self.basePrices = Dictionary(uniqueKeysWithValues: symbols.map { ($0.symbol, $0.price) })
        supervisor = Task { [weak self] in
            await self?.runSupervised()
        }
    }

    func stop() async {
        isRunning = false
        supervisor?.cancel()
        supervisor = nil
        await client.disconnect()
        continuation.yield(.statusChanged(.disconnected))
    }

    // MARK: - Connection Supervision -

    /// Connects and runs the session, reconnecting with exponential backoff if
    /// the connection drops while the feed is still meant to be running.
    private func runSupervised() async {
        var attempt = 0
        while isRunning && !Task.isCancelled {
            continuation.yield(.statusChanged(.connecting))
            await client.connect()
            continuation.yield(.statusChanged(.connected))
            attempt = 0

            await runSession()
            await client.disconnect()

            guard isRunning && !Task.isCancelled else { break }

            // Unexpected drop: report disconnected and back off before retrying.
            continuation.yield(.statusChanged(.disconnected))
            attempt += 1
            let delay = min(pow(2.0, Double(attempt)) * 0.5, maxReconnectDelay)
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    /// Runs the producer and receiver loops concurrently; returns as soon as
    /// either finishes (e.g. on a transport error), cancelling the other.
    private func runSession() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.produceLoop() }
            group.addTask { [weak self] in await self?.receiveLoop() }
            await group.next()
            group.cancelAll()
        }
    }

    // MARK: - Producer -

    private func produceLoop() async {
        while isRunning && !Task.isCancelled {
            let interval = Double.random(in: tickInterval)
            try? await Task.sleep(for: .seconds(interval))
            guard isRunning, !Task.isCancelled else { break }

            guard let symbol = symbols.randomElement(),
                  let base = basePrices[symbol] else { continue }

            var rng = SystemRandomNumberGenerator()
            let newPrice = generator.nextPrice(base: base, using: &rng)
            basePrices[symbol] = newPrice

            let update = PriceUpdate(symbol: symbol, price: newPrice, timestamp: Date())
            do {
                try await client.send(codec.encode(update))
            } catch {
                break // drop out so the supervisor can reconnect
            }
        }
    }

    // MARK: - Receiver -

    private func receiveLoop() async {
        while isRunning && !Task.isCancelled {
            do {
                let text = try await client.receive()
                if let update = codec.decode(text) {
                    continuation.yield(.priceUpdate(update))
                }
            } catch {
                break // transport dropped; let the supervisor reconnect
            }
        }
    }
}
