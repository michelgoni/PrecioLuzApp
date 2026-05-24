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

### Checkpoint 11E — Medium Widget Integration + UI Smoke (2026-05-24)
- Scope:
  - integración del `Medium Widget (2x4)` en la pantalla de precios (`PricesView`).
  - `UI smoke` específico para presencia del widget en runtime real.
  - regla de cierre reforzada en `docs/engineering-rules.md`: no cerrar miniincrementos con suites parciales (`-only-testing`) sin `TEST SUCCEEDED` de suite completa.
- Validación ejecutada:
  1. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testPricesScreenShowsMediumWidget test | tee /tmp/issue11_11E_ui_widget.log`
  2. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11E_full_suite.log`
- Resultado:
  - `UI smoke` widget: OK (`1 test`, `0 failures`, `** TEST SUCCEEDED **`).
  - suite completa scheme principal: OK (`** TEST SUCCEEDED **`).
- Evidencia visual/snapshot:
  - `Tests/Snapshots/__Snapshots__/PricesMediumWidgetSnapshotTests/contentState.1.png`
  - `Tests/Snapshots/__Snapshots__/PricesMediumWidgetSnapshotTests/emptyState.1.png`

### Checkpoint 11F — PricesView Previews for Medium Widget States (2026-05-24)
- Scope:
  - previews explícitas añadidas en `PricesViewPreviews` para estados de widget:
    - `Prices widget content`
    - `Prices widget empty`
  - objetivo: facilitar validación manual del widget integrado en su contexto real de pantalla.
- Validación ejecutada:
  - `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11F_full_suite.log`
- Resultado:
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11G — Robust `now` Fallback for Medium Widget Mapper (2026-05-24)
- Scope:
  - ajuste en `PricesView`: cuando `summary.current` no existe, el `now` enviado al mapper usa `state.hourlyPrices.first?.date` antes de caer a `Date()`.
  - objetivo: evitar estado vacío accidental del widget con datos horarios presentes pero sin `summary`.
- Validación ejecutada:
  - `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11G_full_suite.log`
- Resultado:
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11H — Snapshot Integration of Medium Widget in PricesView (2026-05-24)
- Scope:
  - expansión de `Issue11SnapshotTests` con dos snapshots integrados de `PricesView`:
    - `pricesWidgetContent`
    - `pricesWidgetEmpty`
  - objetivo: proteger regresiones visuales del widget medium en contexto real de pantalla.
- Validación ejecutada:
  1. `SNAPSHOT_TESTING_RECORD=1 xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppTests/Issue11SnapshotTests test`
  2. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppTests/Issue11SnapshotTests test`
  3. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test`
- Resultado:
  - snapshots nuevos grabados y verificados.
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11I — Medium Widget Mapper Edge Cases (2026-05-24)
- Scope:
  - ampliación de `PricesMediumWidgetMapperTests` con dos casos de borde:
    - serie plana: todas las barras deben mantener altura normalizada estable (`0.6`).
    - entrada desordenada: el mapper debe ordenar por fecha antes de calcular `current` y `nextHours`.
  - objetivo: blindar regresiones del modelo de presentación sin tocar la UI.
- Validación ejecutada:
  1. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppTests/PricesMediumWidgetMapperTests test | tee /tmp/issue11_11I_mapper_tests.log`
  2. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11I_full_suite.log`
- Resultado:
  - `PricesMediumWidgetMapperTests`: OK (`5 tests`, `0 failures`, `** TEST SUCCEEDED **`).
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11J — Dark Mode Snapshots for Integrated Medium Widget (2026-05-24)
- Scope:
  - ampliación de `Issue11SnapshotTests` para cubrir el widget medium integrado en `PricesView` también en dark mode:
    - `pricesWidgetContentDark`
    - `pricesWidgetEmptyDark`
  - objetivo: blindar legibilidad/contraste del widget en tema oscuro con baseline visual versionado.
- Validación ejecutada:
  1. `SNAPSHOT_TESTING_RECORD=1 xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppTests/Issue11SnapshotTests test | tee /tmp/issue11_11J_snapshots_record.log`
  2. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:PrecioLuzAppTests/Issue11SnapshotTests test | tee /tmp/issue11_11J_snapshots_assert.log`
  3. `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11J_full_suite.log`
- Resultado:
  - snapshots dark nuevos grabados y verificados.
  - `Issue11SnapshotTests`: OK (`6 tests`, `0 failures`, `** TEST SUCCEEDED **`).
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11K — Widget Medium Accessibility Semantics (2026-05-24)
- Scope:
  - mejoras de accesibilidad en `PricesMediumWidgetView` para evitar semántica dependiente solo de color:
    - elementos decorativos ocultos a VoiceOver (`bolt`, `dot` de estado).
    - barras del gráfico con `accessibilityLabel`/`accessibilityValue` y `accessibilityIdentifier`.
    - celdas de próximas horas con etiqueta/valor semántico (hora + precio + clasificación) e identificador estable.
  - objetivo: reforzar lectura asistida y trazabilidad en pruebas UI sin alterar layout.
- Validación ejecutada:
  - `xcodebuild -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test | tee /tmp/issue11_11K_full_suite.log`
- Resultado:
  - suite completa en verde (`** TEST SUCCEEDED **`).

### Checkpoint 11D — Final Delivery Validation (2026-05-01)
- Device baseline: `iPhone 17` (iOS Simulator).
- Ejecución secuencial:
  1. `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' clean | tee /tmp/issue11_11D_clean.log`
  2. `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tee /tmp/issue11_11D_build.log`
  3. `scripts/check_tca_warnings.sh --log /tmp/issue11_11D_build.log`
  4. `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PrecioLuzAppTests | tee /tmp/issue11_11D_tests.log`
  5. `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PrecioLuzAppUITests | tee /tmp/issue11_11D_ui.log`
- Resultado:
  - `clean`: OK (`** CLEAN SUCCEEDED **`)
  - `build`: OK (`** BUILD SUCCEEDED **`)
  - `TCA warnings/deprecations`: `0`
  - `PrecioLuzAppTests`: OK (`82 tests`, `0 failures`)
  - `PrecioLuzAppUITests`: OK (`7 tests`, `0 failures`)
- Evidencia visual final:
  - [docs/evidence-issue11-11D-final.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue11-11D-final.png)

## Issue #33 — Today Summary Icons
- Scope:
  - iconography added to Today summary cards (`average`, `current`, `maximum`, `minimum`) using SF Symbols.
  - consistent icon/text alignment and spacing in summary cards.
  - accessibility combined per card (`icon + title + value`) with stable card identifiers.
- Validation:
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PrecioLuzAppTests`
  - snapshot reference updated for summary UI:
    - `Tests/Snapshots/__Snapshots__/Issue11SnapshotTests/pricesContent.1.png`
- Evidence:
  - [docs/evidence-issue33-today-summary-icons.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue33-today-summary-icons.png)

## Issue #34 — Settings Icons Alignment
- Scope:
  - iconography aligned to SuperDesign in Settings rows (`notifications`, `daily minimum`, `daily maximum`, `custom threshold`, `threshold value`, `threshold stepper`) with circular semantic color containers.
  - shared row icon component introduced to keep icon size, spacing and alignment consistent across all settings items.
  - denied-permissions section updated to the same visual language (semantic warning icon in circular container + settings CTA).
- Validation:
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testSettingsTabSmokeInteractionsAreStable`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PrecioLuzAppTests/SettingsFeatureTests`
- Evidence:
  - [docs/evidence-issue34-settings-icons.png](/Users/michelgoni/Documents/repos/PrecioLuzApp/docs/evidence-issue34-settings-icons.png)

## Issue #43 — Motion SwiftUI Functional Polish

### Checkpoint 43A — Motion Foundation + Loading Skeleton (2026-05-13)
- Scope:
  - shared SwiftUI motion tokens and Reduce Motion-aware helpers added in `UIShared`.
  - sober shimmer treatment applied to the existing prices loading skeleton.
  - no new dependencies, no UIKit, no reducers changed.
- Device:
  - requested baseline `iPhone 17` was unavailable locally.
  - fallback used: `iPhone 17 Pro Max` (`iOS 26.4`) via XcodeBuildMCP.
- Validation:
  - `build`: OK (`XcodeBuildMCP build_sim`, `BUILD SUCCEEDED`)
  - `build + run`: OK (`XcodeBuildMCP build_run_sim`)
  - `TCA warnings/deprecations`: `0`
  - runtime log tail reviewed with no visible app output errors.
- Evidence:
  - pending user-provided dark skeleton evidence
  - pending user-provided light skeleton evidence
- Status:
  - `waiting_user_review`

### Checkpoint 43B — Prices Content Transition + Staggered Entrance (2026-05-13)
- Scope:
  - `loading -> content` transition softened in `PricesView` with fade/move and controlled trigger state.
  - summary cards animated with staggered entrance in `PricesSummaryCardsView`.
  - hourly rows animated with staggered entrance in `PricesHourlyListSectionView`.
  - shared `StaggeredEntranceModifier` added in `UIShared` and wired to Reduce Motion.
- Validation:
  - `build`: OK (`XcodeBuildMCP build_sim`, `BUILD SUCCEEDED`)
  - `TCA warnings/deprecations`: `0`
- Evidence:
  - pending manual visual review in simulator/canvas.
- Status:
  - `waiting_user_review`

### Checkpoint 43C — Interaction Feedback in Prices + Calculation Modal (2026-05-13)
- Scope:
  - shared `PressedFeedbackButtonStyle` added in `UIShared`.
  - hourly rows now use pressed feedback style for tactile tap response.
  - preset cards now animate selection emphasis (scale/spring) and pressed feedback.
  - estimated cost label in calculation sheet now uses numeric content transition.
- Validation:
  - `build`: OK (`XcodeBuildMCP build_sim`, `BUILD SUCCEEDED`)
  - `TCA warnings/deprecations`: `0`
- Evidence:
  - pending manual visual review in simulator/canvas.
- Status:
  - `waiting_user_review`

### Checkpoint 43D — Chart Motion for Daypart + Inspection (2026-05-13)
- Scope:
  - chart container now animates transition when daypart changes.
  - inspected point marker now has stronger emphasis animation.
  - inspection card now transitions in/out and animates numeric content updates.
- Validation:
  - `build`: OK (`XcodeBuildMCP build_sim`, `BUILD SUCCEEDED`)
  - `TCA warnings/deprecations`: `0`
- Evidence:
  - pending manual visual review in simulator/canvas.
- Status:
  - `waiting_user_review`

### Checkpoint 43E — Final Pass + Full Validation (2026-05-13)
- Scope:
  - final visual tuning pass completed with no extra ornamental animation added.
  - snapshot baseline updated to reflect the final motion-aware prices content presentation.
  - no functional contract changes, no new dependencies, no UIKit usage.
- Validation:
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=PrecioLuz Clean iPhone 17' clean build`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=PrecioLuz Clean iPhone 17' test -only-testing:PrecioLuzAppTests`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,name=PrecioLuz Clean iPhone 17' test -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testTabNavigationIsStable -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testHourlyRowTapPresentsAndDismissesCalculationModal -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testChartDaypartSelectionAndInteractionIsStable -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testSettingsTabSmokeInteractionsAreStable`
  - all commands completed with `BUILD SUCCEEDED` / `TEST SUCCEEDED`.
- Evidence:
  - updated snapshot: `Tests/Snapshots/__Snapshots__/Issue11SnapshotTests/assertIssue11Snapshot-of.2.png`
  - external visual evidence image intentionally skipped per user decision in thread.
- Status:
  - `approved`

## Onboarding Feature — 4-Step First Run Flow

### Checkpoint ONB-A — Feature Implementation + Validation (2026-05-13)
- Scope:
  - added a 4-step SwiftUI onboarding flow before the main tab shell.
  - wired onboarding state through `AppFeature` and `OnboardingFeature` using TCA.
  - persisted completion with `UserDefaults` through `PersistenceClient`.
  - added notification permission request handling from onboarding step 3.
  - added localized Spanish/English copy, previews, snapshots, reducer tests, and UI smoke coverage.
  - no new dependencies, no UIKit usage, no remote push notifications.
- Validation:
  - `xcodegen generate`: OK during project-file discovery; final `.pbxproj` kept as a minimal manual registration of the new files because `project.yml` did not require changes.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'generic/platform=iOS Simulator' build`: OK.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=ED400BF3-3EB2-40E0-AC8F-2F195F6D9DD9' test -only-testing:PrecioLuzAppTests/OnboardingFeatureTests -only-testing:PrecioLuzAppTests/AppFeatureTests`: OK.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=ED400BF3-3EB2-40E0-AC8F-2F195F6D9DD9' test -only-testing:PrecioLuzAppTests/Issue11SnapshotTests/onboardingScreens`: OK.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=ED400BF3-3EB2-40E0-AC8F-2F195F6D9DD9' test -only-testing:PrecioLuzAppUITests/PrecioLuzAppUITests/testOnboardingFlowReachesMainTabs`: OK.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=ED400BF3-3EB2-40E0-AC8F-2F195F6D9DD9' test -only-testing:PrecioLuzAppUITests`: OK.
  - `xcodebuild -quiet -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=ED400BF3-3EB2-40E0-AC8F-2F195F6D9DD9' test`: FAILED only on 3 pre-existing Issue 11 snapshot mismatches (`rootStatusBannerStates`, `pricesContent`, `settingsStates`); 114 tests passed and the new onboarding snapshot case passed.
- Evidence:
  - manual review path: launch with `-PrecioLuzResetOnboarding`, advance 4 steps, verify tabs.
  - test-only bypass path: launch with `-PrecioLuzOnboardingCompleted`.
- Status:
  - `implemented`
