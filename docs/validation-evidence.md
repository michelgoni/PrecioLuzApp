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
  - [docs/evidence-issue8-prices-shell.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue8-prices-shell.png)

## Issue #9 — Chart Feature Validation Trace
- Incremento `9.0` (documental):
  - alcance de gráfico diario, segmentación `Daypart` e inspección puntual documentado
  - regla de parada por miniincremento documentada (review manual obligatoria)
- Incrementos técnicos `9A-9E`:
  - cada checkpoint debe registrar:
    - `build` y tests ejecutados
    - `UI smoke` cuando aplique por flujo visible
    - evidencia visual versionada de la gráfica o de su interacción
- Acceptance (`Testing + TestStore`):
  - `Tests/Acceptance/Issue9AcceptanceTests.swift`
  - `Acceptance #9: chart daypart filtering and inspection follow user flow`
  - `Acceptance #9: chart clears stale inspection after refresh`
- UI smoke (`XCUITest`):
  - `UITests/PrecioLuzAppUITests.swift`
  - `testChartDaypartSelectionAndInteractionIsStable`
  - valida navegación a tab `Gráfica`, cambio de tramo y gesto de interacción sin crash
- Evidencia visual:
  - [docs/evidence-issue9-chart-shell.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue9-chart-shell.png)

## Issue #10 — Settings + Local Notifications Validation Trace
- Acceptance (`Testing + TestStore`):
  - `Tests/Acceptance/Issue10AcceptanceTests.swift`
  - `Acceptance #10: settings changes trigger notification re-scheduling`
  - `Acceptance #10: denied authorization forces notifications off and clears scheduling`
- Dominio puro de scheduling:
  - `Tests/Domain/NotificationSchedulingPlannerTests.swift`
  - cobertura de filtro temporal (futuro + mismo día), mínimo/máximo, umbral y fallback ASAP
- UI smoke (`XCUITest`):
  - `UITests/PrecioLuzAppUITests.swift`
  - `testSettingsTabSmokeInteractionsAreStable`
  - valida navegación a `Ajustes`, toggles principales y presencia operativa del stepper sin crash
- Evidencia visual:
  - [docs/evidence-issue10-settings-shell.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue10-settings-shell.png)

## Issue #11 — QA and Delivery Readiness Validation Trace
- Contrato de ejecución cerrado en incremento documental `11.0`:
  - hardening de resiliencia primero
  - expansión de cobertura de tests después
  - validación final secuencial de entrega al final
- Checkpoints obligatorios de `#11`:
  - `11A`: hardening offline/caché/error + validación de estados raíz y reconciliación
  - `11B`: expansión `Testing + TestStore` y aceptación (`Issue11AcceptanceTests`)
  - `11C`: snapshots críticos + `UI smoke` estable sin redundancia
  - `11D`: `clean build session` + `build` + `PrecioLuzAppTests` + `PrecioLuzAppUITests` + `TCA warnings/deprecations: 0`
- Evidencias esperadas de cierre:
  - logs y comandos de validación final documentados
  - capturas versionadas de estados visuales críticos
  - trazabilidad de PR final lista para merge
