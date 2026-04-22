# Engineering Rules

## Propósito
Este documento convierte el marco de `AGENTS.md` en comportamiento técnico concreto durante la ejecución de tareas. Complementa `AGENTS.md` y no puede contradecirlo.

## Regla general de ejecución
- Antes de implementar, identifica qué parte del sistema cambia y limita el trabajo a ese alcance.
- Prefiere el cambio más pequeño que resuelva el problema de forma mantenible.
- Si una decisión obliga a ampliar alcance, deja el motivo explícito en la respuesta final.

## Preflight de sincronización (obligatorio)
- Antes de cualquier edición, verificar rama activa y estado de sincronización con remoto.
- Si la rama activa es `main`, ejecutar `git pull --ff-only origin main` antes de empezar.
- Si la rama activa es una feature branch, ejecutar `git fetch origin` y comprobar que la base esperada existe y está alineada con `origin/main` antes de editar.
- Si la sincronización falla (conflictos, red, permisos o historial no fast-forward), bloquear la implementación y no continuar sobre un estado desactualizado.

## Disciplina de alcance
- No modificar más de una capa técnica a la vez salvo petición explícita o necesidad directa de integración.
- Capas típicas en este proyecto:
  - UI y navegación
  - lógica de feature o reducer
  - clientes de dependencias
  - persistencia
  - configuración de proyecto
- No tocar archivos no relacionados con la tarea.
- Si una tarea exige tocar archivos adyacentes por compilación, wiring o tests, limita el cambio a lo estrictamente necesario.
- No hacer refactors oportunistas mientras se resuelve otra tarea.

## Lectura mínima antes de cambiar código
- Antes de implementar, revisar `AGENTS.md` y los documentos de `docs/` que afecten a la tarea.
- Si la tarea es de producto o comportamiento, revisar `docs/product-spec.md`.
- Si la tarea afecta arquitectura, estado, dependencias o persistencia, revisar `docs/ios-architecture.md`.
- La estructura por carpetas y la responsabilidad de cada área se toman de `docs/ios-architecture.md` y no deben reorganizarse sin necesidad directa.
- Si la tarea afecta UI, navegación o estética, revisar `docs/ui-direction.md`.
- Si la tarea es ambigua en ejecución, usar `docs/codex-project-prompt.md` como apoyo, nunca como sustituto del marco principal.

## Dependencias
- No introducir dependencias nuevas sin justificarlo de forma explícita.
- Antes de añadir una dependencia, comprobar si el stack aprobado ya cubre el caso.
- Si una dependencia nueva parece necesaria, explicar:
  - por qué no basta con Apple frameworks o dependencias ya aprobadas
  - qué problema concreto resuelve
  - qué coste de mantenimiento introduce
- No sustituir `TCA` ni `sqlite-data` por alternativas sin petición explícita.

## Cambios en código
- Mantener la lógica de negocio fuera de la vista.
- Todo el código debe escribirse en inglés:
  - nombres de tipos
  - clases
  - structs
  - enums
  - protocolos
  - propiedades
  - métodos
  - reducers, states y actions
- Los textos visibles para usuario pueden estar en español; los identificadores de código no.
- Localización (obligatorio):
  - no usar strings literales directas para copy visible al usuario en vistas o componentes;
  - usar siempre claves de localización (`String(localized:)` o equivalente) y registrar la entrada en `Resources/es.lproj/Localizable.strings` y `Resources/en.lproj/Localizable.strings`;
  - en código de UI, evitar `defaultValue` con copy visible al usuario salvo contexto excepcional documentado; preferir claves existentes y sincronizadas en ficheros de localización;
  - evitar cerrar tareas con copy nueva sin claves localizables añadidas.
- Tokens visuales (obligatorio para UI):
  - evitar magic numbers en layout/estilo (`padding`, `spacing`, `cornerRadius`, tamaños) dentro de vistas;
  - definir constantes con intención semántica (por ejemplo `Layout.contentPadding`, `Layout.cardCornerRadius`) en el scope más cercano razonable;
  - cuando el patrón se repita entre pantallas, promover esos tokens a un módulo compartido de design system.
- Orden y consistencia (cuando aplique):
  - Ordenar alfabéticamente `import`s.
  - Ordenar alfabéticamente las propiedades en `struct`s y `class`es si no existe un orden semántico más claro.
  - Ordenar alfabéticamente los `case` en `enum`s.
  - Excepción: mantener orden semántico cuando mejore la lectura del dominio (por ejemplo `Daypart`, o enums que representan un flujo temporal).
- Regla de seguridad (anti-crash, obligatoria):
  - Evitar crashes en runtime como requisito no negociable.
  - Nunca indexar arrays/colecciones sin garantías de rango (out-of-bounds). Preferir iteración segura (`for element in ...`, `enumerated()`), `first/last`, o checks explícitos.
  - Evitar `!` (force unwrap) y `as!` salvo que el valor esté previamente validado con `guard`/`if let` y la invariantes estén claras.
  - Evitar `fatalError`, `preconditionFailure` y `assertionFailure` en código de producto salvo casos excepcionales y documentados.
- Legibilidad y formato (obligatorio):
  - Preferir firmas de funciones en una sola línea cuando sea razonable para lectura (evitar saltos justo después del nombre de la función).
  - Mantener indentación consistente; al tocar un archivo en Xcode, re-indentar con `Control+i` (Editor > Structure > Re-Indent) antes de considerar el cambio listo.
  - Límite de tamaño por extensión/tipo: ninguna `class` (incluyendo sus `extension`) puede superar 400 líneas en un mismo archivo; si se alcanza ese tamaño, es obligatorio separar responsabilidades en archivos/tipos más pequeños antes de cerrar la tarea.
  - Si `SwiftLint` no está aplicando esta regla, tratarla igualmente como bloqueante de revisión y verificarla manualmente en el checkpoint.
- Diseño y claridad de intención (obligatorio):
  - No mezclar responsabilidades distintas dentro del mismo tipo (`class`, `struct`, `enum` o `actor`). Separar clasificación, agregación, cálculo, persistencia y orquestación cuando corresponda.
  - Cada tipo debe tener un propósito principal claro y verificable en su API pública.
  - Evitar funciones con intención opaca o ambigua; el nombre debe explicar la acción y el contexto de dominio (`classifyHourlyPrices`, `buildDailySummary`, `estimateApplianceCost`, etc.).
  - Si una función empieza a concentrar varias intenciones, dividirla en funciones más pequeñas con nombres explícitos.
  - Evitar duplicidades o redundancias en código: no implementar dos veces la misma responsabilidad o comportamiento.
- Control de acceso Swift (obligatorio):
  - Ser explícitos y escrupulosos con el nivel de acceso de cada tipo y miembro (`private`, `fileprivate`, `internal`, `public`, `open`).
  - Aplicar el principio de mínimo acceso necesario: usar el nivel más restrictivo que permita cumplir el caso.
  - Preferir `private` para detalles de implementación y helpers internos al tipo.
  - Elevar a `internal` solo cuando exista uso real entre archivos/módulos dentro del target.
  - Usar `public`/`open` únicamente con una necesidad clara de API externa y justificación explícita en el cambio.
  - En revisiones, tratar como deuda cualquier símbolo más visible de lo necesario.
- En features TCA:
  - introducir cambios primero en `State`, `Action`, `Reducer` y dependencias
  - después ajustar la vista y el wiring mínimo necesario
- Previews SwiftUI (obligatorio):
  - toda vista nueva debe incluir `#Preview` útil para validar layout y estados principales;
  - si se modifica una vista existente, actualizar/añadir previews de los estados afectados por el cambio;
  - no cerrar tareas de UI sin revisar al menos una preview o validación equivalente en simulador.
- Arquitectura de vistas SwiftUI (obligatorio):
  - seguir diseño atómico y granular por componentes siempre que sea posible;
  - evitar vistas monolíticas; dividir en sub-vistas con responsabilidad única y nombres explícitos;
  - extraer piezas reutilizables cuando un bloque visual/funcional se repita o complique la lectura.
- Preferir `async/await` para efectos y clientes.
- Evitar callbacks salvo integración imprescindible.
- Evitar `UIKit` salvo integración necesaria y aislada.
- No introducir abstracciones genéricas o reutilización prematura si el flujo base aún no existe.

## Política de tests (obligatoria)
- No usar `XCTest` para unit/integration tests en este proyecto salvo bloqueo técnico explícito y temporal.
- Excepción permitida: `XCUITest` para pruebas de UI end-to-end en su target dedicado.
- Los tests deben implementarse con el framework `Testing` (`import Testing`, `@Test`, `#expect`, `#require`).
- Para reducers y efectos en `TCA`, seguir el enfoque oficial con `TestStore` descrito en la documentación de TCA:
  - https://pointfreeco.github.io/swift-composable-architecture/1.9.0/documentation/composablearchitecture/testing/
- Para regresión visual de UI, adoptar `SnapshotTesting` (`pointfreeco/swift-snapshot-testing`) como patrón principal de cobertura visual.
- Mantener `SnapshotTesting` integrado en suites basadas en `Testing`; no abrir suites nuevas de `XCTest` para snapshots.
- En snapshots inline:
  - no escribir manualmente el contenido del snapshot en trailing closures;
  - no editar snapshots inline a mano;
  - regenerar snapshots en record mode y revisar diffs.
- Los UI tests se introducen de forma faseada:
  - baseline smoke de wiring con `XCUITest` en hitos de shell/navegación
  - baseline visual de estados con `SnapshotTesting` en hitos de shell/feature
  - expansión de cobertura visual y flujos E2E en hitos de QA
- Para UI tests de comportamiento visible:
  - usar `XCUITest` en un target de UI tests dedicado para smoke/wiring;
  - usar `SnapshotTesting` para matriz de estados y regresión visual.
- Si una suite existente usa `XCTest`, migrarla de forma incremental en el siguiente cambio que toque esa suite.
- Evitar tests redundantes:
  - cada test debe cubrir una intención diferente y aportar señal nueva;
  - no duplicar en aceptación los mismos asserts detallados que ya están cubiertos en unit tests;
  - no duplicar en `XCUITest` la lógica ya validada con `Testing + TestStore`;
  - no duplicar en `XCUITest` verificaciones visuales ya cubiertas con `SnapshotTesting`;
  - mantener tests de aceptación en flujo integrado y tests unitarios en lógica puntual.

## Validación mínima obligatoria
- Tras cambios de documentación:
  - revisar consistencia terminológica
  - verificar enlaces o referencias internas
  - confirmar que no se contradice `AGENTS.md`
- Tras cambios de código sin impacto visual:
  - ejecutar compilación del target/scheme afectado
  - ejecutar `SwiftLint` en modo estricto
  - ejecutar tests automáticos del área afectada (o suite completa si no hay filtrado útil)
  - revisar warnings de compilación y tratarlos como bloqueantes de cierre de tarea cuando afecten al stack aprobado
  - en particular, warnings o deprecations de `TCA` (`swift-composable-architecture`) deben resolverse en el mismo cambio o dejar la tarea abierta hasta su resolución
- Tras cambios de UI, navegación o comportamiento visible:
  - contrastar el resultado con el baseline de diseño aprobado en `Issue #13` y `docs/ui-direction.md`;
  - si existe proyecto Xcode, validar con `build` y simulador mediante `XcodeBuildMCP`
  - incluir `UI smoke tests` en el checkpoint cuando la tarea toque shell/navegación/wiring visible o flujos E2E base
  - arrancar la app y revisar logs de ejecución para detectar errores no visibles
  - realizar chequeo visual básico del flujo tocado y recoger evidencia mínima obligatoria
  - guardar al menos un screenshot por feature tocada dentro de `docs/` y referenciar su ruta en el resumen final de la tarea/PR (si el simulador falla, adjuntar evidencia de preview y dejar la limitación documentada)
- Si no existe proyecto Xcode o no es posible validar, dejar constancia explícita y no presentar la validación como realizada.
- Si aparece un bloqueo de linker/build session (por ejemplo símbolos no resueltos intermitentes):
  - ejecutar `clean build session` del scheme afectado;
  - repetir `build` y `test` en secuencial (no en paralelo) tras el clean;
  - documentar en el checkpoint que se aplicó la mitigación.

### Checklist ejecutable (DoD transversal para tareas con código)
- Clean build session (cuando haya bloqueo de linker/sesión de build):
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' clean`
- Compilación:
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' build`
- Lint:
  - `swiftlint lint --strict`
- Tests:
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' test`
- UI smoke tests (cuando aplique por milestone/scope):
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' -only-testing:<UITestsTarget> test`
- UI snapshot tests (cuando aplique por milestone/scope):
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' -only-testing:<SnapshotTestsTarget> test`
- Logs en ejecución:
  - `xcrun simctl spawn booted log show --style compact --last 5m --predicate 'process == "<AppBinaryName>" AND messageType == error'`
- Evidencia visual mínima (si hay cambio visible):
  - `xcrun simctl io booted screenshot /tmp/precioluzapp-validation.png`
  - mover el archivo a una ruta versionada en el repo, por ejemplo `docs/evidence-<issue>-<feature>.png`

### Reglas de aplicabilidad del checklist
- Si el cambio es solo documental, no aplicar compilación/lint/tests/UI; aplicar únicamente validación documental.
- En mini incrementos de UI, el checkpoint no se considera completo sin:
  - `build` + tests de lógica del scope tocado;
  - `UI smoke tests` cuando aplique por wiring/flujo visible;
  - evidencia visual versionada (screenshot o preview documentada con limitación explícita).
- Si no existe proyecto Xcode todavía, ejecutar lo que sí esté disponible y reportar explícitamente la limitación restante.
- Si `SwiftLint` no está instalado, tratar la validación como incompleta hasta instalarlo o dejar el bloqueo documentado.
- En el alcance base actual no existe backend propio; revisión de logs backend no aplica salvo que se añada un servicio en el repo.

## Integración y entrega
- No mergear trabajo directamente en `main`.
- Cada feature debe llegar a `main` a través de una `Pull Request`.
- El título y la descripción de la `Pull Request` deben estar en inglés.
- Gestión de comentarios de review en PR (obligatorio):
  - responder siempre a cada comentario de review con el contexto del cambio aplicado o la justificación técnica;
  - no aceptar comentarios “porque sí”: antes de cambiar, evaluar si la propuesta mejora realmente el diseño/código/tests y explicar el porqué (incluyendo tradeoffs si aplica);
  - declarar una decisión explícita por comentario: `aplicar`, `aplicar con ajuste` o `no aplicar` con motivo técnico;
  - después de editar, listar de forma explícita qué se cambió (archivo y comportamiento afectado);
  - cerrar cada comentario con el estado de validación ejecutada (`build`, `lint`, `tests`, UI checks cuando aplique);
  - tras aplicar el fix, marcar el hilo como resuelto;
  - no dejar comentarios accionables sin respuesta ni hilos abiertos por omisión.
- Si la `Pull Request` contiene código, el CI mínimo en `GitHub Actions` debe ejecutar al menos `build` y tests, y ambos deben estar en verde antes del merge.
- Si la `Pull Request` es solo documental, no exige `build` Xcode, pero sí debe superar los checks documentales o de formato que existan.
- Si el workflow de CI todavía no existe, dejar constancia explícita de esa limitación y tratar la integración en `main` como bloqueada.
- Cada tarea debe existir primero como `GitHub Issue` descriptiva.
- El título y la descripción de cada `GitHub Issue` deben estar en inglés.
- Cada `Pull Request` debe enlazar su `Issue` de origen (`Closes #...` o `Refs #...`).
- En trabajo paralelo con múltiples `worktrees`, cada `Issue` y cada `Pull Request` deben incluir trazabilidad de dependencias (`Depends on` / `Blocks` o `Unblocks`) para evitar merges fuera de secuencia.

## Flujo de features con GitHub Issues
- Unidad de planificación: una tarea = un `GitHub Issue`.
- Unidad de implementación: una feature branch por issue.
- Convención de rama recomendada: `feature/<issue-id>-<slug-corto>`.
- Contenido mínimo obligatorio de cada issue:
  - contexto y objetivo
  - alcance y fuera de alcance
  - Definition of Done aplicable
  - validación esperada
  - `Depends on` (issues bloqueantes)
  - `Blocks` o `Unblocks` (issues dependientes)
- Un issue no puede pasar a cerrado si sus `Depends on` no están cerradas.
- Para tareas de UI, no empezar implementación visual sin cerrar antes el issue de consenso de diseño vigente en el roadmap (`Issue #13`) o su sucesor explícito.
- Las PR de UI deben incluir una referencia trazable a ese issue de consenso (`Depends on` o `Refs`), además del issue funcional de la tarea.

## Higiene de cambios
- No renombrar archivos, mover directorios o reorganizar estructura sin necesidad directa.
- No editar archivos generados salvo que la tarea lo requiera de forma explícita.
- No mezclar en un mismo cambio ajustes funcionales con limpieza general no relacionada.
- Si el repositorio está sucio, trabajar solo sobre los archivos de la tarea y no revertir cambios ajenos.

## Criterio de cierre
- La tarea no se considera cerrada hasta que:
  - el entregable pedido existe
  - el cambio está alineado con `AGENTS.md`
  - se ha ejecutado la validación mínima posible
  - no quedan warnings activos de `TCA` en el scope tocado (especialmente deprecations con migración disponible)
  - se ha dejado claro el estado de integración por `Pull Request` y CI cuando aplique
  - se ha indicado explícitamente su dependencia respecto a hitos/PR previos y siguientes cuando forme parte de una cadena
  - no se marca como integrada si depende de hitos/PR todavía no integrados
  - cualquier limitación o supuesto queda explicado de forma explícita
