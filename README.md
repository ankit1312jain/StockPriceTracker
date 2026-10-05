# Real-Time Stock Price Tracker

A SwiftUI app that streams live price updates for 25 stock symbols over a
WebSocket echo server and drills into a per-symbol detail screen. Built with
**Clean Architecture**, **Swift 6 strict concurrency**, and a **Swift Testing**
unit suite.

> Assessment note: the brief specified a mandatory `// MARK: - Name - ` comment
> format (leading `- ` and trailing ` - `). That exact convention is used
> throughout, in preference to the idiomatic `// MARK: - Name`.

## Features

- Live prices for 25 symbols over `wss://ws.postman-echo.com/raw` — the app
  generates a random tick, sends it, and renders the echoed message.
- Symbols list: name, current price, and a price-change indicator.
- Two sort orders: **by Price** and **by Price Change**.
- Connection-status indicator (connecting / connected / disconnected) and a
  **Start/Stop** feed control on the list screen.
- Detail screen: symbol title, live price with the *same* indicator, and a
  description — updating in real time, in lock-step with the list.
- Locale-aware currency/percent formatting and localization-ready strings
  (the "multi-regional" requirement).
- Auto-reconnect with exponential backoff; accessible indicators (glyph + colour).

## Architecture

Clean Architecture + MVVM. The dependency rule points inward:
`Presentation → Domain ← Data`, with the App layer as the composition root.

```
StockPriceTracker/
  App/            AppConfiguration, AppContainer (DI), StockPriceTrackerApp
  Domain/         Entities, Repository protocols (ports), SortStocksUseCase
  Data/           URLSessionWebSocketClient (actor), PriceFeedService (actor),
                  RandomPriceGenerator, PriceUpdateCodec, StaticSymbolCatalog
  Presentation/   PriceStore (@Observable), view models, SwiftUI views, components
  Core/           Small cross-cutting helpers
StockPriceTrackerTests/   Swift Testing suite + test doubles
```

### Real-time updates across screens

A single `@Observable @MainActor` **`PriceStore`** is the one source of truth,
injected via the SwiftUI environment. Both the list and detail screens read from
it, so a single applied tick re-renders every screen — no duplicated state.

### Concurrency (Swift 6 strict)

- Networking is isolated inside actors (`URLSessionWebSocketClient`,
  `PriceFeedService`); all cross-boundary payloads are `Sendable`.
- UI state (`PriceStore`, view models) is `@MainActor`.
- The feed exposes one `AsyncStream<FeedEvent>` (status + ticks) that the store
  consumes. Structured concurrency only — no Combine.

### Testability

Everything depends on protocols (`PriceFeedProviding`, `SymbolCatalogProviding`,
an injectable `RandomNumberGenerator`), wired in `AppContainer`. Tests inject
in-memory doubles and a seeded RNG — zero networking, fully deterministic.

## Requirements

- Xcode 26+, iOS 26.5 SDK.

## Running

1. Open `StockPriceTracker.xcodeproj`.
2. Select the `StockPriceTracker` scheme and an iOS 26 simulator.
3. Run. Tap **Start** to begin the feed; tap any row for the detail screen.

## Tests

Run with `Cmd-U` (or `xcodebuild test`). The suite covers the domain change
logic, sorting rules, the price generator (determinism + bounds), JSON
codec (round-trip + lenient decoding), the store's event application and feed
control, and the list view model's sorting/toggle behaviour.

## Project setup notes

The Swift 6 language mode and the unit-test target are configured in the Xcode
project. If re-creating the test target, add a **Unit Testing Bundle**
(Testing framework) named `StockPriceTrackerTests` targeting the app, and set
**Swift Language Version → Swift 6** for both targets.
