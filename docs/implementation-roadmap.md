# Implementation Roadmap

## Goal
Convert the documentation-first repository into a production-ready native iPhone app through small, reversible milestones.

## DoD transversal
- Para hitos con código (`Hito 1` en adelante), el cierre se evalúa con el checklist ejecutable definido en `docs/engineering-rules.md` (compilación, lint, tests, logs y validación visual cuando aplique).
- `Hito 0` es documental y se valida con su DoD específico.
- `Hito 1.5` es documental y se valida con su DoD específico.

## Dependencias entre hitos
- `Hito 0 -> Hito 1`
- `Hito 1 -> Hito 1.5`
- `Hito 1.5 -> Hito 2`
- `Hito 2 -> Hito 3`
- `Hito 3 -> Hito 4`
- `Hito 3 -> Hito 6`
- `Hito 3 -> Hito 7`
- `Hito 4 -> Hito 5`
- `Hito 4 -> Hito 8`
- `Hito 5 -> Hito 8`
- `Hito 6 -> Hito 8`
- `Hito 7 -> Hito 8`

## Estados de cierre por hito
- `Done-Local`: entregable implementado y DoD técnico superado en la rama de trabajo.
- `Done-Integrated`: `Pull Request` mergeada en `main`, CI en verde y todas sus dependencias previas también en `Done-Integrated`.

## Regla de secuencia para trabajo paralelo
- Un hito no puede marcarse como `Done-Integrated` si su hito previo en la cadena de dependencias no está en `Done-Integrated`.
- Para evitar huecos de planificación, no cerrar un hito como "final" sin tener el siguiente hito de la cadena creado como `GitHub Issue` (aunque quede en estado `Blocked`).
- En trabajo con múltiples worktrees, cada `Issue` y cada PR deben declarar de forma explícita su `Depends on` (hito/issue/PR previo) y su `Blocks` o `Unblocks` (hito/issue/PR siguiente) cuando aplique.

## Milestones

### Hito 0 — Coherencia del repo
- unificar naming del producto
- preparar `.gitignore` para Xcode y SwiftPM
- documentar la estructura futura del proyecto

#### Definition of Done (DoD)
- todo artefacto de documentación y repo raíz usa `PrecioLuzApp` como nombre canónico del producto
- `.gitignore` incluye entradas mínimas para Xcode y SwiftPM
- existe documentación explícita de la estructura futura del proyecto en `docs/ios-architecture.md`

#### Validación mínima obligatoria
- ejecutar `rg -n "(AhorraLuz|PrecioLuz)" .` y confirmar que no quedan nombres de producto antiguos fuera de contexto histórico o referencias externas justificadas
- inspeccionar `.gitignore` y verificar presencia de patrones de Xcode (`DerivedData`, `.xcworkspace/xcuserdata`, `.xcodeproj/xcuserdata`) y SwiftPM (`.build`, `.swiftpm`)
- revisar `docs/ios-architecture.md` y confirmar que la estructura de carpetas propuesta está descrita y alineada con `AGENTS.md`

### Hito 1 — Bootstrap técnico
- crear proyecto Xcode `iPhone`
- añadir `TCA` y `sqlite-data`
- crear shell base con tabs y tests mínimos
  - tabs iniciales: `Precios`, `Gráfica`, `Ajustes`
  - iconografía de tabs con `SF Symbols` (`eurosign.circle`, `chart.xyaxis.line`, `gearshape`)
  - contenido inicial de cada tab: placeholder mínimo
  - títulos de tabs preparados para localización (`Localizable.strings`)
- configurar CI inicial de `build` y `test`

### Hito 1.5 — Consenso de diseño visual
- issue objetivo: `#13`
- cerrar contrato visual de implementación en `docs/ui-direction.md`
- fijar tokens, semántica y patrones UI mínimos antes de empezar features visuales
- dejar trazabilidad explícita de dependencias `Depends on` y `Blocks` para issues de UI

#### Definition of Done (DoD)
- `Issue #13` cerrada con consenso explícito documentado
- `docs/ui-direction.md` define baseline accionable para ejecución iOS
- hitos/issues de UI referencian la dependencia de consenso visual

#### Validación mínima obligatoria
- revisar consistencia con `AGENTS.md`, `docs/product-spec.md` y `docs/ios-architecture.md`
- verificar que la secuencia de dependencias del roadmap impide saltar directamente de bootstrap a implementación UI

### Hito 2 — Núcleo de dominio y dependencias
- modelar tipos base de negocio
- crear clientes inyectables para precios, persistencia, fecha y notificaciones
- preparar pipeline de snapshot diario y caché
- dejar evaluada la estrategia de modularización por capas (`Domain -> Clients -> Persistence`) como paso previo al siguiente hito

#### Regla de transición `Hito 2 -> Hito 3`
- Antes de iniciar `Hito 3`, revisar explícitamente si conviene extraer Swift Packages por capas.
- No modularizar por feature UI en esta transición salvo necesidad técnica fuerte y justificada.

### Hito 3 — Shell de aplicación y estados raíz
- consolidar `AppFeature`
- introducir estados `loading`, `empty`, `error` y `cached`
- centralizar formato visual y utilidades compartidas

### Hito 4 — Feature `Prices`
- cards de resumen
- lista horaria
- selección de franja
- tratamiento visual de la hora actual y caché

### Hito 5 — Feature `CostCalculation`
- presets cerrados
- duración editable
- cálculo de coste desde una sola franja base

### Hito 6 — Feature `Chart`
- gráfico diario con `Charts`
- segmentación por `Daypart`
- inspección visual por tramo

### Hito 7 — Feature `Settings` y notificaciones
- toggles y umbral personalizado
- permisos locales
- reprogramación de notificaciones para horas futuras

### Hito 8 — QA y preparación de entrega
- endurecer offline/caché/error
- ampliar tests
- validar simulador y CI antes de merge por PR
