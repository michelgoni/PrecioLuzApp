# Validation Evidence

## Issue #4 — Milestone 1 Technical Bootstrap
- Tabs visible baseline screenshot:
  - [docs/evidence-m1-tabs-visible.jpg](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-m1-tabs-visible.jpg)
- Tabs fullscreen screenshot after launch-screen fix (no letterbox):
  - [docs/evidence-m1-tabs-fullscreen.jpg](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-m1-tabs-fullscreen.jpg)

## Issue #7 — Prices Feature Visual Baseline
- Prices tab screenshot in simulator (`iPhone 17 Pro`, iOS 26.4):
  - [docs/evidence-issue7-shell-prices.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue7-shell-prices.png)

## Issue #8 — Cost Calculation Acceptance Baseline
- Acceptance flow covered in `Testing`:
  - `Tests/Acceptance/Issue8AcceptanceTests.swift`
  - validates modal calculation result (`price * powerKW * duration`)
  - validates stale hour cleanup + modal dismissal after refresh
- UI smoke wiring for modal visibility:
  - `UITests/PrecioLuzAppUITests.swift`
  - `testHourlyRowTapPresentsAndDismissesCalculationModal`
  - `testChartTabDoesNotPresentCalculationModal`
- Visual evidence:
  - pending capture in simulator during review checkpoint of this mini increment
