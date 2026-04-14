# UI Direction

## Gate de consenso (Issue #13)
- Este documento actúa como contrato de diseño para la `Issue #13` (`[Design] Define and approve app visual design baseline`).
- Las tareas con implementación visual deben tratar este baseline como prerequisito de ejecución.
- Dependencias actuales de trazabilidad:
  - `Depends on`: `#4` (Technical Bootstrap)
  - `Blocks`: `#6`, `#7`, `#8`, `#9`, `#10`
- Ninguna issue de UI debe cerrarse sin referenciar este contrato y sus decisiones cerradas.

## Entregables mínimos de consenso
- Tokenización base cerrada:
  - roles de color (`cheap`, `mid`, `expensive`, fondos y superficies)
  - jerarquía tipográfica
  - reglas de spacing, radius y elevación visual
- Patrones de pantalla cerrados para:
  - resumen diario
  - lista horaria
  - interacción de gráfica
  - ajustes y notificaciones locales
- Criterios mínimos de accesibilidad listos para validación en implementación:
  - contraste suficiente
  - semántica no dependiente solo de color
  - touch targets cómodos
  - formatos `es-ES`
- Registro de decisiones:
  - decisiones cerradas
  - decisiones abiertas
  - fecha y responsable de cada cierre

## Intención visual
La app debe transmitir control, claridad y rapidez de lectura. La referencia es un producto iPhone oscuro, contemporáneo y claramente nativo, con información energética legible de un vistazo.

## Dirección general
- Base visual oscura.
- Superficies con profundidad, contraste medido y sensación premium.
- Jerarquía centrada en bloques grandes y contenido escaneable.
- Navegación inferior moderna con tratamiento de glass nativo cuando la API esté disponible.

## Principios de diseño
- La primera lectura debe responder tres preguntas:
  - cuánto cuesta ahora,
  - cuál es el contexto del día,
  - qué hora conviene elegir.
- La información crítica no debe competir con elementos decorativos.
- La gráfica debe sentirse técnica pero accesible.
- La interfaz debe verse propia de iOS, no como un dashboard web reempaquetado.

## Color y semántica

### Paleta funcional
- `cheap`: verde profundo y limpio.
- `mid`: naranja cálido y claramente distinguible.
- `expensive`: rojo intenso pero controlado.
- Fondo: negro o carbón suave.
- Superficies: grises oscuros con elevación sutil.
- Acentos: usar el color del sistema solo donde aporte navegación o foco.

### Reglas
- El color del estado de precio debe repetirse de forma consistente en lista, resumen y gráfica cuando aplique.
- Nunca depender solo del color; acompañar con texto, posición o icono.
- Evitar saturación excesiva en todas las tarjetas a la vez. El énfasis debe reservarse para el dato más relevante.

## Tipografía
- Usar tipografía nativa de Apple.
- Dar más peso a precio y hora que al texto auxiliar.
- Las cifras en `€/kWh` deben priorizar estabilidad visual y legibilidad.
- Los títulos de tabs y secciones deben ser cortos y directos.

## Componentes principales

### Resumen diario
- Cuatro cards superiores:
  - `Actual`
  - `Media`
  - `Mínimo`
  - `Máximo`
- Deben leerse como un bloque de diagnóstico rápido.
- Cada tarjeta puede usar un indicador de color o icono asociado al estado, sin sobrecargar el fondo.

### Lista horaria
- Filas altas, táctiles y fácilmente escaneables.
- Cada fila debe funcionar como una tarjeta o celda expandida, no como una lista densa.
- El color de fondo o banda lateral debe comunicar el estado de precio.
- La hora actual debe tener un tratamiento especial, por ejemplo borde, halo o badge.

### Modal de cálculo
- Debe sentirse compacto y claro.
- Los presets de electrodoméstico deben presentarse como opciones directas y reconocibles.
- El resultado del coste debe tener una jerarquía visual fuerte.
- Evitar formularios largos.

### Gráfica
- Usar `Charts` nativo.
- Mantener grid y ejes sutiles.
- La línea o área de precio debe tener contraste suficiente en fondo oscuro.
- El punto inspeccionado debe resaltar con claridad.
- La selección del tramo debe ser simple y táctil, idealmente en control segmentado o tratamiento equivalente nativo.

### Ajustes
- Pantalla sobria, con grupos claros.
- Los toggles deben ser protagonistas.
- El umbral personalizado debe quedar próximo al switch que lo activa.

## Liquid Glass y materiales
- Adoptar efectos de glass nativos en navegación inferior, overlays o contenedores destacados cuando mejoren profundidad y foco.
- No aplicar glass de forma indiscriminada.
- Los materiales translúcidos deben preservar contraste de texto e iconos.
- Si el glass compite con la legibilidad, priorizar superficie opaca elegante.

## Motion
- Microanimaciones cortas y funcionales.
- Cambios de estado suaves al seleccionar franja, cambiar tramo del gráfico y mostrar el modal.
- Evitar animaciones largas o puramente ornamentales.

## Estados visuales

### Loading
- Skeletons o placeholders sobrios.
- Mantener la estructura de cards y lista para reducir salto visual.

### Empty
- Mensaje breve y accionable.
- Debe explicar si faltan datos o si todavía no se han cargado.

### Error
- Explicar el fallo sin jerga.
- Si hay caché disponible, priorizar mostrar el dato persistido con aviso discreto.

### Cached
- Mostrar que el dato es persistido sin alarmar al usuario.

## Accesibilidad mínima obligatoria
- Contraste suficiente entre texto y superficies.
- No depender solo del color para distinguir estados.
- Objetivos táctiles cómodos para lista, tabs y toggles.
- Etiquetas accesibles para tarjetas de resumen, filas horarias y puntos de la gráfica.
- Formatos de hora y moneda coherentes con `es-ES`.

## Anti-patrones a evitar
- Tarjetas pequeñas con texto comprimido.
- Gráficas demasiado brillantes o saturadas.
- Glass aplicado a toda la pantalla.
- Exceso de badges, iconos o adornos sin función.
- Un look visual genérico o demasiado parecido a una plantilla de dashboard.
