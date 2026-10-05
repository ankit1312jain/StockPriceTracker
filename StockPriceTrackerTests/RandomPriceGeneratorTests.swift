//
//  RandomPriceGeneratorTests.swift
//  StockPriceTrackerTests
//
//  Verifies the simulated price walk is deterministic and bounded.
//

import Testing
import Foundation
@testable import StockPriceTracker

// MARK: - RandomPriceGeneratorTests -

struct RandomPriceGeneratorTests {

    @Test func deterministicForSameSeed() {
        let generator = RandomPriceGenerator(maxMovePercent: 0.02)
        var rngA = SeededRandomNumberGenerator(seed: 42)
        var rngB = SeededRandomNumberGenerator(seed: 42)
        #expect(
            generator.nextPrice(base: 100, using: &rngA)
            == generator.nextPrice(base: 100, using: &rngB)
        )
    }

    @Test func staysWithinConfiguredBounds() {
        let generator = RandomPriceGenerator(maxMovePercent: 0.02)
        var rng = SeededRandomNumberGenerator(seed: 7)
        for _ in 0..<1_000 {
            let price = generator.nextPrice(base: 100, using: &rng)
            #expect(price >= Decimal(string: "97.9")!)
            #expect(price <= Decimal(string: "102.1")!)
        }
    }

    @Test func neverFallsBelowMinimum() {
        let minimum = Decimal(string: "0.01")!
        let generator = RandomPriceGenerator(maxMovePercent: 1.0, minimumPrice: minimum)
        var rng = SeededRandomNumberGenerator(seed: 99)
        for _ in 0..<1_000 {
            let price = generator.nextPrice(base: Decimal(string: "0.02")!, using: &rng)
            #expect(price >= minimum)
        }
    }
}
