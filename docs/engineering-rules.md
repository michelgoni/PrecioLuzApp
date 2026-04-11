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
- Si la tarea afecta UI, navegación o estética, revisar `docs/ui-direction.md`.
- Si la tarea es ambigua en ejecución, usar `docs/codex-project-prompt.md` como apoyo, nunca como sustituto del marco principal.

## Dependencias
- No introducir dependencias nuevas sin justificarlo de forma explícita.
- Antes de añadir una dependencia, comprobar si el stack aprobado ya cubre el caso.
- Si una dependencia nueva parece necesaria, explicar:
  - por qué no basta con Apple frameworks o dependencias ya aprobadas,
  - qué problema concreto resuelve,
  - qué coste de mantenimiento introduce.
- No sustituir `TCA` ni `sqlite-data` por alternativas sin petición explícita.

## Cambios en código
- Mantener la lógica de negocio fuera de la vista.
- Todo el código debe escribirse en inglés:
  - nombres de tipos,
  - clases,
  - structs,
  - enums,
  - protocolos,
  - propiedades,
  - métodos,
  - reducers, states y actions.
- Los textos visibles para usuario pueden estar en español; los identificadores de código no.
- En features TCA:
  - introducir cambios primero en `State`, `Action`, `Reducer` y dependencias,
  - después ajustar la vista y el wiring mínimo necesario.
- Preferir `async/await` para efectos y clientes.
- Evitar callbacks salvo integración imprescindible.
- Evitar `UIKit` salvo integración necesaria y aislada.
- No introducir abstracciones genéricas o reutilización prematura si el flujo base aún no existe.

## Validación mínima obligatoria
- Tras cambios de documentación:
  - revisar consistencia terminológica,
  - verificar enlaces o referencias internas,
  - confirmar que no se contradice `AGENTS.md`.
- Tras cambios de código sin impacto visual:
  - ejecutar la validación mínima disponible, preferiblemente compilación o tests del área afectada.
- Tras cambios de UI, navegación o comportamiento visible:
  - si existe proyecto Xcode, validar con `build` y simulador mediante `XcodeBuildMCP`,
  - si aplica, inspeccionar UI y recoger screenshot o logs.
- Si no existe proyecto Xcode o no es posible validar, dejar constancia explícita y no presentar la validación como realizada.

## Integración y entrega
- No mergear trabajo directamente en `main`.
- Cada feature debe llegar a `main` a través de una `Pull Request`.
- Si la `Pull Request` contiene código, el CI mínimo en `GitHub Actions` debe ejecutar al menos `build` y tests, y ambos deben estar en verde antes del merge.
- Si la `Pull Request` es solo documental, no exige `build` Xcode, pero sí debe superar los checks documentales o de formato que existan.
- Si el workflow de CI todavía no existe, dejar constancia explícita de esa limitación y tratar la integración en `main` como bloqueada.
- Cada feature o hito debe registrarse como item del backlog en el GitHub Project del proyecto.
- Antes de aprobar una `Pull Request`, el backlog debe contener una tarjeta o item que identifique esa `Pull Request`.

## Higiene de cambios
- No renombrar archivos, mover directorios o reorganizar estructura sin necesidad directa.
- No editar archivos generados salvo que la tarea lo requiera de forma explícita.
- No mezclar en un mismo cambio ajustes funcionales con limpieza general no relacionada.
- Si el repositorio está sucio, trabajar solo sobre los archivos de la tarea y no revertir cambios ajenos.

## Criterio de cierre
- La tarea no se considera cerrada hasta que:
  - el entregable pedido existe,
  - el cambio está alineado con `AGENTS.md`,
  - se ha ejecutado la validación mínima posible,
  - se ha dejado claro el estado de integración por `Pull Request` y CI cuando aplique,
  - cualquier limitación o supuesto queda explicado de forma explícita.
