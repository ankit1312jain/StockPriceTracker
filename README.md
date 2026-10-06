# Real-Time Stock Price Tracker

A SwiftUI app that streams live price updates for 25 stock symbols over a
WebSocket echo server and drills into a per-symbol detail screen. Built with
**Clean Architecture**, **Swift 6 strict concurrency**, and a **Swift Testing**
unit suite.

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
- Resilient connection lifecycle: auto-reconnect with exponential backoff,
  real connection state driven by the WebSocket delegate, and scene-aware
  pause/resume on backgrounding. Accessible indicators (glyph + colour).

## Tech Stack

| Area | Technology |
|---|---|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI |
| State | Observation — `@Observable`, `@Environment` |
| Concurrency | Swift `actor`, `AsyncStream`, structured concurrency (no Combine) |
| Networking | `URLSessionWebSocketTask` + `URLSessionWebSocketDelegate` |
| Formatting | `FormatStyle` (locale-aware currency/percent) |
| Navigation | `NavigationStack` + value-based `navigationDestination` |
| Testing | Swift Testing, in-memory fakes, seeded RNG |
| CI | GitHub Actions (`macos-26`, Xcode 26) |

## Architecture

Clean Architecture + MVVM. The dependency rule points inward:
`Presentation → Domain ← Data`, with the App layer as the composition root.

```
StockPriceTracker/
  App/            AppConfiguration, AppContainer (DI), StockPriceTrackerApp
  Domain/         Entities, Repository protocols (ports), SortStocksUseCase
  Data/           URLSessionWebSocketClient (actor) + WebSocketConnecting port,
                  WebSocketConnectionState, PriceFeedService (actor),
                  RandomPriceGenerator, PriceUpdateCodec, StaticSymbolCatalog
  Presentation/   PriceStore (@Observable), view models, SwiftUI views, components
  Core/           Small cross-cutting helpers
StockPriceTrackerTests/   Swift Testing suite + test doubles
```

### WebSocket data flow

The app is **both producer and consumer**: it fabricates a random tick, sends it
to the echo endpoint, and renders the echoed message — so the "real-time" feed
is simulated client-side (exactly what the assessment's echo integration asks
for).

```
RandomPriceGenerator ──price──▶ PriceUpdate ──encode──▶ PriceUpdateCodec (JSON)
                                                              │ send()
                                                              ▼
                                        URLSessionWebSocketClient (actor)
                                                              │
                                   wss://ws.postman-echo.com/raw  (echo server)
                                                              │ receive()
                                                              ▼
                                        URLSessionWebSocketClient (actor)
                                                              │ decode()
                                                              ▼
                         PriceFeedService (actor) ──FeedEvent──▶ AsyncStream
                                                              │
                                                              ▼
                              PriceStore (@MainActor, @Observable)
                                                              │
                                                              ▼
                     SymbolsListView   &   SymbolDetailView   (update live)
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

### Connection lifecycle & resilience

- **Real connection state.** `URLSessionWebSocketClient` adopts
  `URLSessionWebSocketDelegate` and publishes a `WebSocketConnectionState`
  stream from the actual `didOpen` / `didClose` / `didCompleteWithError`
  callbacks. Status reflects the real handshake rather than being assumed the
  moment the task resumes; `PriceFeedService` maps it onto the domain
  `ConnectionStatus`.
- **Auto-reconnect.** A supervising task reconnects with exponential backoff
  (capped) whenever the transport drops while the feed is meant to be running.
- **Scene-aware pause/resume.** The app observes `@Environment(\.scenePhase)`:
  it suspends the socket on `.background` and resumes it on `.active`, while
  **ignoring `.inactive`** so transient interruptions (Control Center, the app
  switcher, an incoming call) don't drop the feed. The user's Start/Stop intent
  is preserved across backgrounding, so the feed only resumes if it was on.

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

## Continuous Integration

A GitHub Actions workflow (`.github/workflows/ci.yml`) builds the app and runs
the full unit-test suite on every push and pull request to `main`
(`xcodebuild test` against the shared `StockPriceTracker` scheme). Tests are
hermetic — they use in-memory fakes and a seeded RNG, so there is no network
dependency and runs are deterministic.

To stay aligned with the project's toolchain, the workflow:

- runs on the `macos-26` image and selects the newest installed Xcode, so the
  **iOS 26.5 SDK** this app targets is available;
- picks an available iPhone simulator **by UDID at runtime** instead of pinning
  a device name, so the destination survives Xcode / runner-image updates.

## Design decisions & possible improvements

Deliberate trade-offs:

- **Client-simulated feed.** The echo endpoint reflects whatever is sent, so the
  app generates ticks locally and consumes the echo. This matches the brief and
  keeps the feed fully testable.
- **`Decimal`, not `Double`, for money.** Prices/changes use `Decimal` with
  `NSDecimalRound` to avoid floating-point drift in currency values.
- **3-case `ConnectionStatus`.** Transport failures map to `.disconnected` — the
  backoff supervisor retries regardless, so a separate `failed` case would add
  UI/test surface without product value.
- **No ping/keep-alive.** The producer sends a frame every <1s, so a dead socket
  surfaces almost immediately; a heartbeat would be redundant here.

Possible future enhancements:

- Persisted, user-selectable watchlist.
- Historical price charts on the detail screen.
- A remote, region-specific symbol catalog (the `SymbolCatalogProviding` port
  already allows swapping the static catalog with zero changes upstream).
- Search/filter and pull-to-refresh on the list.
- Snapshot / UI tests for the two screens.

## Project setup notes

The Swift 6 language mode and the unit-test target are configured in the Xcode
project. If re-creating the test target, add a **Unit Testing Bundle**
(Testing framework) named `StockPriceTrackerTests` targeting the app, and set
**Swift Language Version → Swift 6** for both targets.
