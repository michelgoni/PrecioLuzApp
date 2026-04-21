# AGENTS.md

## Propósito
- Construir `PrecioLuzApp` como una app `iPhone` nativa centrada en precios horarios de electricidad y avisos locales útiles.
- Priorizar `SwiftUI`, `async/await` y APIs nativas actuales con una experiencia visual claramente iOS.
- Mantener cambios pequeños, reversibles y verificables.

## Reglas no negociables
- Target mínimo: `iOS 26+`.
- UI y arquitectura: `SwiftUI`, `Swift Concurrency`, `Charts`, `UserNotifications`, `URLSession` y `The Composable Architecture`.
- Política técnica: Apple-first. Las excepciones aprobadas actuales son `pointfreeco/swift-composable-architecture` para gestión de estado y composición, `pointfreeco/sqlite-data` para persistencia y caché, y `pointfreeco/swift-snapshot-testing` para regresión visual en tests.
- Preferir `async/await` y evitar APIs basadas en callbacks salvo necesidad real de integración.
- Evitar `UIKit` salvo integración imprescindible con APIs del sistema o limitaciones concretas de `SwiftUI`.
- Idioma inicial de la app: español, con estructura preparada para localización futura.
- Todo el código, incluyendo nombres de tipos, clases, propiedades, métodos, reducers, acciones y estados, debe escribirse en inglés.
- Las notificaciones del producto son locales; no usar APS remotas en el alcance base.

## Límites de alcance
- No usar notificaciones push remotas.
- No optimizar prematuramente antes de que exista un flujo base funcional y verificable.

## Forma de trabajar
- No inventes arquitectura ni convenciones si todavía no están definidas en el repo.
- Usa los documentos de `docs/` como fuente de verdad para el detalle funcional, técnico y visual.
- La configuración estructural del proyecto vive en `project.yml` (`XcodeGen`); si cambian targets, paquetes, settings o estructura del proyecto, actualizar primero `project.yml` y después regenerar `PrecioLuzApp.xcodeproj`.
- El workflow CI activo está en `.github/workflows/ci.yml` y usa `xcodebuild -resolvePackageDependencies`, `xcodebuild ... -skipMacroValidation build` y `xcodebuild ... test` con el scheme compartido del proyecto.
- Cuando la tarea se ejecute en `worktree` o `detached HEAD`, mantener igualmente el preflight de sincronización y comprobar alineación con `origin/main` antes de editar.
- `AGENTS.md` define marco, límites y prioridades.
- `docs/engineering-rules.md` es la fuente única de reglas operativas de ejecución: preflight, disciplina de alcance, validación, integración por PR, CI y trazabilidad con issues/dependencias.
- `docs/codex-project-prompt.md` es un apoyo de ejecución concreta y no puede reemplazar ni contradecir este archivo.
- Si dos documentos entran en conflicto, prioriza este archivo y después `docs/product-spec.md`.
- Comandos base alineados con el workflow actual de CI:
  - `xcodebuild -resolvePackageDependencies -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination "generic/platform=iOS Simulator" -skipMacroValidation build`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -showdestinations`
  - `xcodebuild -project PrecioLuzApp.xcodeproj -scheme PrecioLuzApp -destination 'platform=iOS Simulator,id=<simulator-id>' -skipMacroValidation test`

## Contexto del proyecto
- Producto y contrato funcional: `docs/product-spec.md`
- Arquitectura y decisiones técnicas: `docs/ios-architecture.md`
- Reglas operativas de ingeniería: `docs/engineering-rules.md`
- Dirección visual y UX: `docs/ui-direction.md`
- Roadmap y dependencias entre hitos: `docs/implementation-roadmap.md`
- Evidencia visual versionada de validaciones: `docs/validation-evidence.md`
- Prompt auxiliar de ejecución para Codex: `docs/codex-project-prompt.md`
