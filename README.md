# AhorraLuzApp ⚡📱

> A native iPhone app to understand electricity prices at a glance, explore daily trends, and get smart local alerts before expensive hours hit.

## ✨ What is this project?

`AhorraLuzApp` is an iPhone-first app focused on Spanish hourly electricity pricing.

The goal is simple:

- 🟢 show when electricity is cheap
- 🟠 highlight mid-range hours
- 🔴 warn when prices are expensive
- 🧮 help users estimate appliance cost from a selected hour
- 🔔 schedule local notifications for daily minimums, maximums, and custom thresholds

This project is also intentionally being used as a learning playground for:

- 🧩 The Composable Architecture (`TCA`)
- 🍎 modern native iOS development
- 🪟 SwiftUI-first UI patterns
- 🧪 testable feature design

## 📲 Planned app experience

The app is designed around **three tabs**:

### 1. Prices ⏰
- Daily summary cards for current, average, minimum, and maximum price
- A 24-hour price list
- Color-coded hourly slots for cheap, mid, and expensive periods
- A modal cost calculator when the user taps a time slot

### 2. Chart 📈
- A daily chart split into clear day sections
- Fast visual comparison between time ranges
- Hourly inspection for a selected time segment

### 3. Settings ⚙️
- Local notification toggles
- Daily minimum alert
- Daily maximum alert
- Custom price-threshold alert

## 🧠 Product direction

The current product definition assumes:

- 🇪🇸 Spanish market pricing with `ESIOS/PVPC` as the initial source of truth
- 📆 up to `30 days` of local history
- 🔔 local notifications only
- 📱 iPhone-only scope for the base version
- 🌙 a dark, modern, native iOS visual direction

## 🏗️ Tech direction

The project documentation currently defines this stack:

- `SwiftUI`
- `Swift Concurrency`
- `Charts`
- `UserNotifications`
- `URLSession`
- `The Composable Architecture`
- `sqlite-data`

Key engineering rules already established:

- 📝 all code identifiers must be in English
- 🚫 no direct merges to `main`
- 🔀 every feature must go through a Pull Request
- ✅ code PRs must pass CI (`build` + tests) before merge
- 📋 every feature or milestone must also be tracked in the project backlog

## 📚 Documentation map

The repository is currently documentation-first.

If you want the full project definition, start here:

- `AGENTS.md` — project governance, boundaries, and priorities
- `docs/product-spec.md` — functional product contract
- `docs/ios-architecture.md` — technical structure and TCA direction
- `docs/engineering-rules.md` — execution rules for implementation work
- `docs/ui-direction.md` — visual and UX direction
- `docs/codex-project-prompt.md` — lightweight execution prompt template

## 🚧 Current status

This repository is at the **foundation stage**.

Right now it contains:

- ✅ project-level guidance
- ✅ product scope
- ✅ architecture decisions
- ✅ engineering rules
- ✅ UI direction

Not included yet:

- ❌ Xcode project bootstrap
- ❌ app implementation
- ❌ GitHub Actions workflow
- ❌ tests
- ❌ simulator-validated UI

## 🎯 Next logical milestones

- 1. Create the Xcode project and initial app target
- 2. Set up TCA root structure
- 3. Add the first GitHub Actions workflow
- 4. Implement the `Prices` feature
- 5. Add persistence and notifications
- 6. Validate flows on simulator

## 💛 Why this project exists

This app is meant to be both:

- a useful product for understanding electricity pricing
- a well-documented native iOS reference project for building with modern Apple APIs and TCA

---

Built with ⚡ energy data, 📱 native iOS ideas, and 🧠 a strong bias toward clarity.
