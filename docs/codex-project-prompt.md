# Codex Project Prompt

Usa este documento como plantilla operativa auxiliar para una tarea concreta. Complementa `AGENTS.md`, no lo sustituye y no puede contradecirlo.

## Uso correcto
- Úsalo para encuadrar una tarea concreta, no para redefinir normas del proyecto.
- Trata `docs/engineering-rules.md` como fuente única para ejecución técnica (preflight, alcance, validación, PR/CI e issues/dependencias).
- Si este documento entra en conflicto con `AGENTS.md`, manda `AGENTS.md`.

## Plantilla mínima de ejecución

```md
<task_context>
Proyecto: PrecioLuzApp
Tarea: [describir aquí el cambio pedido]
Área afectada: [feature, pantalla o capa técnica]
Tipo de cambio: [documentación | código sin impacto visible | UI/comportamiento visible]
</task_context>

<required_docs>
- AGENTS.md
- docs/engineering-rules.md
- docs/product-spec.md (si aplica)
- docs/ios-architecture.md (si aplica)
- docs/ui-direction.md (si aplica)
</required_docs>

<execution_contract>
- Aplicar el cambio más pequeño y reversible posible.
- Limitar el cambio al alcance pedido.
- Declarar explícitamente cualquier limitación de validación.
- En cada miniincremento: parar tras checkpoint y esperar validación explícita del usuario.
</execution_contract>

<response_expectations>
- Resumen del cambio real aplicado.
- Validación ejecutada de verdad (según `docs/engineering-rules.md`).
- Resultado explícito del control de TCA: `TCA warnings/deprecations: 0|N`.
- Supuestos, bloqueos o límites pendientes.
</response_expectations>

<checkpoint_example>
- Build:
  - `xcodebuild ... build 2>&1 | tee /tmp/precioluzapp-build.log`
- TCA warning scan (bloqueante):
  - `scripts/check_tca_warnings.sh --log /tmp/precioluzapp-build.log`
- Si el script devuelve error:
  - bloquear cierre del incremento y no avanzar al siguiente.
</checkpoint_example>
```

## Notas
- Mantén este documento ligero.
- No dupliques aquí reglas que ya estén definidas en `AGENTS.md` o `docs/engineering-rules.md`.
