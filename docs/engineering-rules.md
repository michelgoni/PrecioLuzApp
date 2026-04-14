# Engineering Rules

## Propósito
Este documento convierte el marco de `AGENTS.md` en comportamiento técnico concreto durante la ejecución de tareas. Complementa `AGENTS.md` y no puede contradecirlo.

## Regla general de ejecución
- Antes de implementar, identifica qué parte del sistema cambia y limita el trabajo a ese alcance.
- Prefiere el cambio más pequeño que resuelva el problema de forma mantenible.
- Si una decisión obliga a ampliar alcance, deja el motivo explícito en la respuesta final.

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
- En features TCA:
  - introducir cambios primero en `State`, `Action`, `Reducer` y dependencias
  - después ajustar la vista y el wiring mínimo necesario
- Preferir `async/await` para efectos y clientes.
- Evitar callbacks salvo integración imprescindible.
- Evitar `UIKit` salvo integración necesaria y aislada.
- No introducir abstracciones genéricas o reutilización prematura si el flujo base aún no existe.

## Validación mínima obligatoria
- Tras cambios de documentación:
  - revisar consistencia terminológica
  - verificar enlaces o referencias internas
  - confirmar que no se contradice `AGENTS.md`
- Tras cambios de código sin impacto visual:
  - ejecutar compilación del target/scheme afectado
  - ejecutar `SwiftLint` en modo estricto
  - ejecutar tests automáticos del área afectada (o suite completa si no hay filtrado útil)
- Tras cambios de UI, navegación o comportamiento visible:
  - si existe proyecto Xcode, validar con `build` y simulador mediante `XcodeBuildMCP`
  - arrancar la app y revisar logs de ejecución para detectar errores no visibles
  - realizar chequeo visual básico del flujo tocado y recoger evidencia mínima (screenshot o logs)
- Si no existe proyecto Xcode o no es posible validar, dejar constancia explícita y no presentar la validación como realizada.

### Checklist ejecutable (DoD transversal para tareas con código)
- Compilación:
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' build`
- Lint:
  - `swiftlint lint --strict`
- Tests:
  - `xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' test`
- Logs en ejecución:
  - `xcrun simctl spawn booted log show --style compact --last 5m --predicate 'process == "<AppBinaryName>" AND messageType == error'`
- Evidencia visual mínima (si hay cambio visible):
  - `xcrun simctl io booted screenshot /tmp/precioluzapp-validation.png`

### Reglas de aplicabilidad del checklist
- Si el cambio es solo documental, no aplicar compilación/lint/tests/UI; aplicar únicamente validación documental.
- Si no existe proyecto Xcode todavía, ejecutar lo que sí esté disponible y reportar explícitamente la limitación restante.
- Si `SwiftLint` no está instalado, tratar la validación como incompleta hasta instalarlo o dejar el bloqueo documentado.
- En el alcance base actual no existe backend propio; revisión de logs backend no aplica salvo que se añada un servicio en el repo.

## Integración y entrega
- No mergear trabajo directamente en `main`.
- Cada feature debe llegar a `main` a través de una `Pull Request`.
- El título y la descripción de la `Pull Request` deben estar en inglés.
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
  - se ha dejado claro el estado de integración por `Pull Request` y CI cuando aplique
  - se ha indicado explícitamente su dependencia respecto a hitos/PR previos y siguientes cuando forme parte de una cadena
  - no se marca como integrada si depende de hitos/PR todavía no integrados
  - cualquier limitación o supuesto queda explicado de forma explícita
