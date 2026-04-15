# Product Spec

## Resumen
`PrecioLuzApp` es una app nativa para `iPhone` que muestra el precio horario de la electricidad en España, conserva un histórico reciente y permite programar avisos locales para ayudar al usuario a consumir en las horas más convenientes.

La fuente de verdad inicial es `ESIOS/PVPC`. La primera versión trabaja con el día actual y un histórico persistido de `30 días`.

## Objetivo del producto
- Mostrar de forma inmediata el precio actual y el contexto del día.
- Permitir detectar rápido qué horas son baratas, medias o caras.
- Ofrecer una calculadora simple de coste por electrodoméstico desde una hora concreta.
- Dar visibilidad gráfica por tramos del día.
- Avisar de oportunidades y picos mediante notificaciones locales.

## Usuario objetivo
- Usuario doméstico en España que consulta el precio de la luz varias veces al día.
- Necesita entender rápido cuándo conviene poner ciertos electrodomésticos.
- No quiere configurar sistemas complejos ni depender de cuentas o backend propio.

## Alcance funcional v1
- App orientada solo a `iPhone`.
- Datos del día actual con persistencia de `30 días`.
- Tres tabs: `Precios`, `Gráfica`, `Ajustes`.
- Navegación preparada para localización de títulos de tabs mediante `Localizable.strings` (idioma inicial `es`).
- Notificaciones locales por mínimo, máximo y umbral personalizado.
- Sin login, sin backend propio, sin notificaciones push remotas.

## Fuente de datos y reglas de negocio
- Fuente de verdad inicial: `ESIOS/PVPC`.
- La app debe persistir el día actual y conservar hasta `30 días` de histórico local.
- Si no hay red, la app debe mostrar el último dato persistido disponible con indicación de dato en caché cuando la UI exista.
- Las horas del día se modelan en horario local de España.
- La clasificación visual de precio es relativa al conjunto del día:
  - `barata`: tercio inferior del día por precio.
  - `intermedia`: tercio medio.
  - `cara`: tercio superior.
- En caso de empate en precio, se conserva el orden horario natural para estabilizar la clasificación.

## Navegación principal

### Tab 1: `Precios`
Objetivo: lectura rápida del estado del día y exploración por horas.

Contenido:
- Cabecera con tarjetas de resumen para `Actual`, `Media`, `Mínimo` y `Máximo`.
- Lista de las 24 franjas horarias del día.
- Cada fila debe comunicar visualmente si la hora es `barata`, `intermedia` o `cara`.

Reglas de presentación:
- `barata` en verde.
- `intermedia` en naranja.
- `cara` en rojo.
- La información clave por fila es hora y precio en `€/kWh`.
- La hora actual debe poder distinguirse visualmente del resto cuando la implementación exista.

Interacción:
- Al pulsar una franja se abre un modal de cálculo.
- El modal parte de la hora seleccionada y deja elegir un preset cerrado de electrodoméstico:
  - `Lavadora`: `2.0 kW`
  - `Vitro`: `1.8 kW`
  - `Aire acondicionado`: `1.2 kW`
- El usuario introduce la duración.
- Fórmula del cálculo:
  - `coste = precio_hora_en_eur_kwh * potencia_kw * duracion_horas`
- La v1 asume una sola hora de precio base, anclada en la hora seleccionada; no reparte el cálculo entre múltiples franjas aunque la duración cruce a la siguiente hora.

### Tab 2: `Gráfica`
Objetivo: ver la evolución del precio diario por bloques fáciles de explorar.

Contenido:
- Una gráfica del día con segmentación fija por franjas.
- Selector de tramos:
  - `Madrugada`: `00:00-05:59`
  - `Mañana`: `06:00-11:59`
  - `Tarde`: `12:00-17:59`
  - `Noche`: `18:00-23:59`

Comportamiento:
- La gráfica muestra los precios horarios del tramo seleccionado.
- Debe permitir inspección puntual del valor de una hora concreta cuando la UI exista.
- La hora actual puede destacarse con un marcador vertical o resaltado equivalente.

### Tab 3: `Ajustes`
Objetivo: controlar notificaciones y preferencias básicas del usuario.

Contenido:
- Toggle global para activar o desactivar notificaciones.
- Toggle para aviso del mínimo diario.
- Toggle para aviso del máximo diario.
- Campo/selector para un umbral personalizado en `€/kWh`.

Reglas de notificación:
- Todas las notificaciones son locales.
- Se recalculan y programan al cargar datos del día.
- Solo se programan para horas futuras del mismo día.
- Aviso del mínimo diario: se programa para la franja más barata futura.
- Aviso del máximo diario: se programa para la franja más cara futura.
- Aviso por umbral: se programa para cada franja futura cuyo precio sea menor o igual al umbral definido.
- La v1 usa un margen fijo de aviso de `15 minutos` antes del inicio de la franja.
- Si la app carga los datos cuando faltan menos de `15 minutos` para la franja, se dispara el aviso lo antes posible dentro del sistema local.

## Dirección visual relacionada
- La dirección visual completa vive en `docs/ui-direction.md`.
- Este documento solo fija implicaciones funcionales del producto; no debe convertirse en segunda fuente de reglas visuales.

## Estados necesarios
- `loading`: mientras se carga el día actual o el histórico.
- `empty`: cuando todavía no hay precios disponibles.
- `error`: cuando falla la carga y no hay caché útil.
- `cached`: cuando se muestra información persistida por ausencia temporal de red.

## Criterios de éxito funcional
- El usuario entiende el estado del precio del día en menos de unos segundos.
- Puede localizar una hora barata sin interpretar tablas complejas.
- Puede calcular rápidamente el coste estimado de un electrodoméstico típico.
- Puede activar avisos sin salir de la app ni crear cuenta.
