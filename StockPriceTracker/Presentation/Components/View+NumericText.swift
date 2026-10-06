//
//  View+NumericText.swift
//  StockPriceTracker
//
//  Shared styling for live-updating numeric text (prices and changes).
//

import SwiftUI

// MARK:  -  Numeric Text Styling  -

extension View {

    /// Renders live-updating numbers with monospaced digits and an animated
    /// numeric transition, so ticking prices/changes don't jitter and animate
    /// smoothly. Reused anywhere a changing number is shown.
    func animatedNumericText() -> some View {
        monospacedDigit()
            .contentTransition(.numericText())
    }
}
