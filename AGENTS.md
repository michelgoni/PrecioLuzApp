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
- Si existe proyecto Xcode, cualquier cambio que afecte UI, navegación o comportamiento visible debe validarse con `build` y simulador mediante `XcodeBuildMCP`.
- Si todavía no existe proyecto Xcode o no es posible validar, deja constancia explícita de la limitación y no presentes la validación como realizada.
- Cada feature debe integrarse en `main` a través de una `Pull Request`; no hacer merge directo a `main`.
- El título y la descripción de cada `Pull Request` deben redactarse en inglés.
- Si la `Pull Request` contiene código, el CI mínimo en `GitHub Actions` debe incluir al menos `build` y ejecución de tests, y ambos deben estar en verde antes del merge.
- Si la `Pull Request` es solo documental, no requiere `build` Xcode, pero sí debe pasar cualquier check documental configurado.
- Si todavía no existe workflow de CI en `GitHub Actions`, la feature no debe considerarse lista para merge; esa ausencia debe quedar señalada explícitamente como bloqueo de integración.
- Cada tarea debe crearse como `GitHub Issue` descriptiva antes de iniciar implementación.
- El título y la descripción de cada `GitHub Issue` deben redactarse en inglés.
- Cada `GitHub Issue` debe documentar dependencias explícitas (`Depends on` y `Blocks`) cuando aplique.
- Cada tarea debe implementarse en una feature branch asociada a su issue.
- Cada `Pull Request` debe enlazar su `Issue` de origen y respetar sus dependencias declaradas.

## Límites de alcance
- No usar notificaciones push remotas.
- No optimizar prematuramente antes de que exista un flujo base funcional y verificable.

## Forma de trabajar
- No inventes arquitectura ni convenciones si todavía no están definidas en el repo.
- Usa los documentos de `docs/` como fuente de verdad para el detalle funcional, técnico y visual.
- `AGENTS.md` define marco, límites y prioridades.
- `docs/engineering-rules.md` concreta cómo ejecutar tareas técnicas dentro de ese marco.
- `docs/codex-project-prompt.md` es un apoyo de ejecución concreta y no puede reemplazar ni contradecir este archivo.
- Si dos documentos entran en conflicto, prioriza este archivo y después `docs/product-spec.md`.

## Contexto del proyecto
- Producto y contrato funcional: `docs/product-spec.md`
- Arquitectura y decisiones técnicas: `docs/ios-architecture.md`
- Reglas operativas de ingeniería: `docs/engineering-rules.md`
- Dirección visual y UX: `docs/ui-direction.md`
- Prompt auxiliar de ejecución para Codex: `docs/codex-project-prompt.md`
