# Codex Project Prompt

Usa este documento como prompt operativo auxiliar del proyecto. Complementa `AGENTS.md`, no lo sustituye y no puede contradecirlo.

## Uso correcto
- Úsalo para encuadrar una tarea concreta, no para redefinir normas del proyecto.
- Antes de ejecutar, consulta siempre:
  - `AGENTS.md`
  - `docs/engineering-rules.md`
  - `docs/product-spec.md`
  - `docs/ios-architecture.md`
  - `docs/ui-direction.md` cuando la tarea afecte UI
- Si este documento entra en conflicto con `AGENTS.md`, manda `AGENTS.md`.

## Plantilla de ejecución

```md
<task_context>
Proyecto: PrecioLuzApp
Tarea: [describir aquí el cambio pedido]
Área afectada: [feature, pantalla o capa técnica]
Documentos a revisar:
- AGENTS.md
- docs/engineering-rules.md
- docs/product-spec.md
- docs/ios-architecture.md
- docs/ui-direction.md (si aplica)
</task_context>

<execution_focus>
- Limita el cambio al alcance pedido.
- No toques archivos no relacionados.
- Si necesitas ampliar alcance, explica por qué.
- Mantén alineación con TCA, stack aprobado y naming en inglés para identificadores de código.
</execution_focus>

<validation>
- Ejecuta la validación mínima realmente disponible para la tarea.
- Si no puedes validar, explica la limitación de forma explícita.
- No presentes validaciones no ejecutadas como realizadas.
</validation>

<response_expectations>
- Resume el cambio real.
- Lista supuestos o límites si existen.
- Indica qué validación se ejecutó de verdad.
</response_expectations>
```

## Notas
- Mantén este documento ligero.
- No dupliques aquí reglas de alcance, arquitectura o validación que ya vivan mejor en `AGENTS.md` o `docs/engineering-rules.md`.
