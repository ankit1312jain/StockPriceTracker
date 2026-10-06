//
//  SeededRandomNumberGenerator.swift
//  StockPriceTrackerTests
//
//  Deterministic RNG so random-driven logic can be tested reproducibly.
//

import Foundation

// MARK:  -  SeededRandomNumberGenerator  -

/// A tiny, deterministic xorshift generator used to make random-based code
/// (e.g. ``RandomPriceGenerator``) fully reproducible in tests.
struct SeededRandomNumberGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        // Avoid the degenerate all-zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
