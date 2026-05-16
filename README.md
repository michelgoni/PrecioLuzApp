# PrecioLuzApp ⚡📱

> La app nativa de iPhone para saber **cuándo conviene consumir electricidad en España** sin interpretar tablas complejas.

`PrecioLuzApp` ayuda a usuarios domésticos con tarifa indexada o PVPC a entender el precio horario de la luz, localizar las mejores horas del día y recibir avisos locales antes de los momentos más caros o más interesantes.

La propuesta no es solo mostrar precios: es convertir datos horarios en decisiones simples.

## Propuesta de valor

- Ver el precio actual de la luz en segundos.
- Detectar rápidamente las horas baratas, medias y caras del día.
- Comparar visualmente la evolución diaria por tramos.
- Estimar el coste de usar electrodomésticos en una hora concreta.
- Recibir avisos locales sobre mínimos, máximos y umbrales personalizados.
- Funcionar sin cuenta, sin backend propio y con una experiencia iPhone-first.

## Para quién es

`PrecioLuzApp` está pensada para personas en España que consultan el precio de la electricidad durante el día y quieren decidir mejor cuándo usar lavadora, lavavajillas, termo, climatización u otros consumos domésticos.

El caso de uso principal es claro:

> “Quiero saber de un vistazo si ahora es buen momento para consumir electricidad o si me conviene esperar.”

## Experiencia principal

La app se organiza alrededor de tres tabs:

### 1. Precios ⏰

Lectura rápida del día:

- tarjetas de resumen para precio actual, media, mínimo y máximo;
- listado horario completo;
- clasificación visual por hora barata, media o cara;
- resaltado de la hora actual;
- acceso al cálculo estimado de coste desde una franja horaria.

### 2. Gráfica 📈

Exploración visual del precio:

- gráfica diaria con `Charts` nativo;
- segmentación por madrugada, mañana, tarde y noche;
- inspección puntual de una hora concreta;
- comparación rápida entre tramos del día.

### 3. Ajustes ⚙️

Control de avisos locales:

- activar o desactivar notificaciones;
- aviso del mínimo diario;
- aviso del máximo diario;
- aviso por umbral personalizado en `€/kWh`.

## Diferenciación de producto

Muchas herramientas muestran el precio de la luz. `PrecioLuzApp` busca diferenciarse por:

- **claridad inmediata**: semáforo horario y resumen diario sin ruido;
- **decisión accionable**: saber cuándo consumir, no solo cuánto cuesta;
- **experiencia nativa iOS**: SwiftUI, Charts, animaciones funcionales y diseño oscuro moderno;
- **privacidad y simplicidad**: sin login, sin cuenta y sin servidor propio en el alcance base;
- **avisos locales**: utilidad diaria sin depender de push remotas.

## Alcance actual

La implementación actual está orientada a una base comercializable de MVP avanzado:

- ✅ proyecto iPhone generado con `XcodeGen`;
- ✅ arquitectura basada en `SwiftUI`, `TCA` y `Swift Concurrency`;
- ✅ tabs `Precios`, `Gráfica` y `Ajustes`;
- ✅ modelos de dominio y clientes inyectables;
- ✅ integración de datos `REE/ESIOS` mediante clave local;
- ✅ persistencia local e histórico reciente;
- ✅ cálculo estimado de coste por electrodoméstico;
- ✅ notificaciones locales para mínimo, máximo y umbral;
- ✅ estados de resiliencia: loading, empty, error, cached y retry;
- ✅ cobertura de tests, snapshots y UI smoke;
- ✅ CI de `build` + `test`.

## Datos y precisión

La app usa `REE/ESIOS` como fuente inicial para precios horarios del mercado español.

El cálculo de coste de electrodomésticos es una estimación basada en potencia y duración. Esto permite validar el flujo de producto en el MVP, pero no debe presentarse como consumo real medido.

Evoluciones naturales del producto:

- perfiles personalizados de electrodoméstico;
- consumo por ciclo introducido desde etiqueta energética;
- cálculo multi-hora cuando un ciclo cruza varias franjas;
- integración futura con medición real mediante enchufes inteligentes, Home Assistant o estándares compatibles.

## Posicionamiento App Store

Posicionamiento recomendado:

> Ahorra atención, no solo céntimos: consulta la luz, encuentra las mejores horas y recibe avisos útiles desde tu iPhone.

Ideas de subtítulo:

- `Precio de la luz y avisos útiles`
- `Encuentra las horas baratas del día`
- `Decide cuándo consumir electricidad`

Promesa principal:

> Entiende el precio horario de la luz y decide mejor cuándo usar tus electrodomésticos.

Ver estrategia ampliada en [`docs/app-store-positioning.md`](docs/app-store-positioning.md).

## Dirección de monetización

La app encaja mejor con un modelo `freemium`:

- versión gratuita para consulta diaria, resumen, gráfica básica y avisos esenciales;
- versión Pro para personalización avanzada, alertas inteligentes, widgets, perfiles de electrodoméstico, histórico ampliado y mejores estimaciones de coste.

No se recomienda monetizar el simple acceso al precio horario. El valor de pago debería estar en la capa de decisión: recomendaciones, personalización, automatización y análisis.

## Stack técnico

- `SwiftUI`
- `Swift Concurrency`
- `Charts`
- `UserNotifications`
- `URLSession`
- `The Composable Architecture`
- `sqlite-data`
- `SnapshotTesting`
- `XcodeGen`

## Clave local REE/ESIOS

Los datos reales de `REE/ESIOS` se cargan desde el secreto local `REE_API_KEY`. La clave no debe commitearse.

Para desarrollo local, crea un archivo `.env` en la raíz del repo:

```env
REE_API_KEY=tu_token_local
```

El scheme compartido solo guarda `PRECIOLUZ_ENV_FILE=$(SRCROOT)/.env`, que es una ruta local no secreta. En ejecuciones Debug de simulador, `XcodeGen` copia ese `.env` al bundle como `PrecioLuzLocal.env`. Ese recurso generado es salida local de build, no se versiona y se elimina en configuraciones no Debug.

## Documentación

- [`AGENTS.md`](AGENTS.md) — gobierno del proyecto, límites y prioridades.
- [`docs/product-spec.md`](docs/product-spec.md) — contrato funcional del producto.
- [`docs/app-store-positioning.md`](docs/app-store-positioning.md) — posicionamiento, ASO, capturas y monetización.
- [`docs/ios-architecture.md`](docs/ios-architecture.md) — estructura técnica y responsabilidades.
- [`docs/engineering-rules.md`](docs/engineering-rules.md) — reglas de ejecución, validación, CI y PRs.
- [`docs/ui-direction.md`](docs/ui-direction.md) — dirección visual y UX.
- [`docs/implementation-roadmap.md`](docs/implementation-roadmap.md) — roadmap de implementación.
- [`docs/validation-evidence.md`](docs/validation-evidence.md) — evidencias de validación.
- [`docs/codex-project-prompt.md`](docs/codex-project-prompt.md) — prompt auxiliar de ejecución.

## Principio de producto

`PrecioLuzApp` no debe sentirse como una tabla de precios. Debe sentirse como una decisión rápida:

> “Ahora sí”, “mejor espera” o “ponlo en esta franja”.
