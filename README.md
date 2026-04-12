# PrecioLuzApp ⚡📱

> A native iPhone app to understand electricity prices at a glance, explore daily trends, and get smart local alerts before expensive hours hit.

## ✨ What is this project?

`PrecioLuzApp` is an iPhone-first app focused on Spanish hourly electricity pricing.

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

## 🚧 Current status

The repository is still in the documentation and planning stage.

Right now it contains:

- ✅ project-level guidance
- ✅ product scope
- ✅ architecture decisions
- ✅ engineering rules
- ✅ UI direction
- ✅ implementation roadmap
- ✅ planned feature-folder responsibilities

Not included yet:

- ❌ Xcode project bootstrap
- ❌ app implementation
- ❌ GitHub Actions workflow
- ❌ tests
- ❌ simulator-validated UI

## 📚 Documentation map

If you want the full project definition, start here:

- `AGENTS.md` — project governance, boundaries, and priorities
- `docs/product-spec.md` — functional product contract
- `docs/ios-architecture.md` — technical structure and planned folder responsibilities
- `docs/engineering-rules.md` — execution rules for implementation work
- `docs/ui-direction.md` — visual and UX direction
- `docs/implementation-roadmap.md` — step-by-step delivery roadmap
- `docs/codex-project-prompt.md` — lightweight execution prompt template

---

Built with ⚡ energy data, 📱 native iOS ideas, and 🧠 a strong bias toward clarity.
