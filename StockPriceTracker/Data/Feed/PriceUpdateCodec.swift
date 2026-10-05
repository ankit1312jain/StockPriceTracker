//
//  PriceUpdateCodec.swift
//  StockPriceTracker
//
//  Serialises price ticks to/from the JSON exchanged over the echo socket.
//

import Foundation

// MARK: - PriceUpdateCodec -

/// Encodes a ``PriceUpdate`` into the JSON string we send over the WebSocket,
/// and decodes the echoed string back into a ``PriceUpdate``.
///
/// Decoding is *lenient*: malformed payloads return `nil` rather than throwing,
/// so a stray frame on the shared echo endpoint can never crash the feed.
///
/// Marked `nonisolated` so the off-main feed `actor` can use it under the
/// project's `MainActor`-by-default isolation. It is stateless (encoder/decoder
/// are created per call), which keeps it trivially `Sendable`.
nonisolated struct PriceUpdateCodec: Sendable {

    // MARK: - DTO -

    private struct PriceUpdateDTO: Codable {
        let symbol: String
        let price: Decimal
        let timestamp: TimeInterval
    }

    // MARK: - Encoding -

    func encode(_ update: PriceUpdate) throws -> String {
        let dto = PriceUpdateDTO(
            symbol: update.symbol,
            price: update.price,
            timestamp: update.timestamp.timeIntervalSince1970
        )
        let data = try JSONEncoder().encode(dto)
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Decoding -

    func decode(_ text: String) -> PriceUpdate? {
        guard let data = text.data(using: .utf8),
              let dto = try? JSONDecoder().decode(PriceUpdateDTO.self, from: data)
        else { return nil }
        return PriceUpdate(
            symbol: dto.symbol,
            price: dto.price,
            timestamp: Date(timeIntervalSince1970: dto.timestamp)
        )
    }
}
