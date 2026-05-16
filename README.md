# PrecioLuzApp ⚡📱

> A native iPhone app that helps people in Spain decide **when it is worth using electricity** without reading complex price tables.

`PrecioLuzApp` helps domestic users with PVPC or indexed electricity tariffs understand hourly electricity prices, spot the best hours of the day, and receive useful local alerts before expensive or convenient time slots arrive.

The product goal is not only to display prices. The goal is to turn hourly market data into simple everyday decisions.

## Value proposition

- See the current electricity price in seconds.
- Quickly identify cheap, mid-range, and expensive hours.
- Compare the daily price curve by time segment.
- Estimate appliance usage cost from a selected hour.
- Receive local alerts for daily minimums, maximums, and custom thresholds.
- Stay iPhone-first, privacy-conscious, and simple: no account and no backend in the base scope.

## Target user

`PrecioLuzApp` is designed for people in Spain who check electricity prices during the day and want to make better decisions about when to use appliances such as washing machines, dishwashers, water heaters, cooking devices, or climate control.

The main user job is simple:

> “I want to know at a glance whether now is a good time to use electricity or whether I should wait.”

## Core app experience

The app is organized around three tabs:

### 1. Prices ⏰

Fast daily reading:

- summary cards for current, average, minimum, and maximum price;
- complete hourly price list;
- visual classification for cheap, mid-range, and expensive slots;
- current-hour highlighting;
- access to an estimated appliance cost calculation from any selected hourly slot.

### 2. Chart 📈

Visual price exploration:

- native `Charts` daily graph;
- fixed daypart segmentation: overnight, morning, afternoon, and night;
- point inspection for a selected hour;
- quick comparison between different parts of the day.

### 3. Settings ⚙️

Local alert control:

- notification enablement;
- daily minimum alert;
- daily maximum alert;
- custom threshold alert in `€/kWh`.

## Product differentiation

Many tools show electricity prices. `PrecioLuzApp` aims to differentiate through:

- **immediate clarity**: hourly traffic-light semantics and daily summary without noise;
- **actionable decisions**: knowing when to consume, not only how much electricity costs;
- **native iOS quality**: SwiftUI, Charts, functional motion, and a modern dark visual direction;
- **privacy and simplicity**: no login, no account, and no own backend in the base scope;
- **local alerts**: daily utility without relying on remote push notifications.

## Current scope

The current implementation is positioned as an advanced MVP foundation:

- ✅ iPhone project generated with `XcodeGen`;
- ✅ architecture based on `SwiftUI`, `TCA`, and `Swift Concurrency`;
- ✅ `Prices`, `Chart`, and `Settings` tabs;
- ✅ domain models and injectable clients;
- ✅ `REE/ESIOS` data integration through a local API key;
- ✅ local persistence and recent history;
- ✅ estimated appliance cost calculation;
- ✅ local notifications for daily minimum, daily maximum, and threshold alerts;
- ✅ resilience states: loading, empty, error, cached, and retry;
- ✅ test coverage, snapshots, and UI smoke tests;
- ✅ CI workflow for `build` and `test`.

## Data and precision

The app uses `REE/ESIOS` as the initial source of truth for Spanish hourly electricity prices.

Appliance cost calculation is currently an estimate based on power and duration. This is valid for MVP validation, but it should not be presented as real measured consumption.

Natural product evolutions include:

- custom appliance profiles;
- energy-per-cycle values entered from energy labels;
- multi-hour calculation when an appliance cycle crosses hourly slots;
- future integration with real measurements through smart plugs, Home Assistant, or compatible standards.

## Technical stack

- `SwiftUI`
- `Swift Concurrency`
- `Charts`
- `UserNotifications`
- `URLSession`
- `The Composable Architecture`
- `sqlite-data`
- `SnapshotTesting`
- `XcodeGen`

## Local REE/ESIOS API key

Real `REE/ESIOS` data is loaded from the local `REE_API_KEY` secret. The key must not be committed.

For local development, create a repo-root `.env` file:

```env
REE_API_KEY=your_local_token
```

The shared Xcode scheme only stores `PRECIOLUZ_ENV_FILE=$(SRCROOT)/.env`, which is a non-secret local path. For simulator Debug runs, `XcodeGen` copies the local `.env` into the built app bundle as `PrecioLuzLocal.env`. That generated bundle resource is local build output only; it is not tracked and is removed for non-Debug configurations.

## Documentation

- [`AGENTS.md`](AGENTS.md) — project governance, boundaries, and priorities.
- [`docs/product-spec.md`](docs/product-spec.md) — functional product contract.
- [`docs/app-store-positioning.md`](docs/app-store-positioning.md) — App Store positioning, ASO, screenshots, and monetization direction.
- [`docs/ios-architecture.md`](docs/ios-architecture.md) — technical structure and planned responsibilities.
- [`docs/engineering-rules.md`](docs/engineering-rules.md) — execution, validation, CI, and PR rules.
- [`docs/ui-direction.md`](docs/ui-direction.md) — visual and UX direction.
- [`docs/implementation-roadmap.md`](docs/implementation-roadmap.md) — implementation roadmap.
- [`docs/validation-evidence.md`](docs/validation-evidence.md) — validation evidence.
- [`docs/codex-project-prompt.md`](docs/codex-project-prompt.md) — lightweight execution prompt template.

## Product principle

`PrecioLuzApp` should not feel like a price table. It should feel like a fast decision:

> “Use electricity now”, “wait”, or “choose this cheaper slot”.
