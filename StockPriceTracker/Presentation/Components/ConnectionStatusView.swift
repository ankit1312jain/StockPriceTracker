//
//  ConnectionStatusView.swift
//  StockPriceTracker
//
//  Connection status indicator shown on the symbols list screen.
//

import SwiftUI

// MARK:  -  ConnectionStatusView  -

/// A small dot-plus-label indicator reflecting the live feed connection state.
struct ConnectionStatusView: View {

    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Connection status: \(statusText)"))
    }

    private var color: Color {
        switch status {
        case .connected:    .green
        case .connecting:   .orange
        case .disconnected: .gray
        }
    }

    private var label: LocalizedStringKey {
        switch status {
        case .connected:    "Connected"
        case .connecting:   "Connecting…"
        case .disconnected: "Disconnected"
        }
    }

    /// Plain, localized status word used for the accessibility label.
    private var statusText: String {
        switch status {
        case .connected:    String(localized: "Connected")
        case .connecting:   String(localized: "Connecting…")
        case .disconnected: String(localized: "Disconnected")
        }
    }
}
