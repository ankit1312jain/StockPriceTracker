//
//  PriceUpdateCodecTests.swift
//  StockPriceTrackerTests
//
//  Verifies JSON round-tripping and lenient decoding of price ticks.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - PriceUpdateCodecTests -

struct PriceUpdateCodecTests {

    private let sut = PriceUpdateCodec()

    @Test func encodeThenDecodePreservesData() throws {
        let original = PriceUpdate(
            symbol: "AAPL",
            price: Decimal(string: "229.87")!,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let text = try sut.encode(original)
        let decoded = try #require(sut.decode(text))
        #expect(decoded.symbol == original.symbol)
        #expect(decoded.price == original.price)
        #expect(decoded.timestamp == original.timestamp)
    }

    @Test func malformedPayloadsDecodeToNil() {
        #expect(sut.decode("not json") == nil)
        #expect(sut.decode("") == nil)
        #expect(sut.decode(#"{"unexpected": true}"#) == nil)
    }
}
