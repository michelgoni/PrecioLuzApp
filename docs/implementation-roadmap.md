# Implementation Roadmap

## Goal
Convert the documentation-first repository into a production-ready native iPhone app through small, reversible milestones.

## Milestones

### Hito 0 — Coherencia del repo
- unificar naming del producto
- preparar `.gitignore` para Xcode y SwiftPM
- documentar la estructura futura del proyecto

### Hito 1 — Bootstrap técnico
- crear proyecto Xcode `iPhone`
- añadir `TCA` y `sqlite-data`
- crear shell base con tabs y tests mínimos
- configurar CI inicial de `build` y `test`

### Hito 2 — Núcleo de dominio y dependencias
- modelar tipos base de negocio
- crear clientes inyectables para precios, persistencia, fecha y notificaciones
- preparar pipeline de snapshot diario y caché

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
