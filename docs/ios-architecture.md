# iOS Architecture

## Resumen técnico
La app debe construirse como una base `iPhone-first` en `iOS 26+`, con `SwiftUI` y APIs modernas de Apple. La arquitectura debe favorecer lectura clara, cambios pequeños y validación frecuente en simulador. La gestión de estado y composición debe apoyarse en `The Composable Architecture` (`TCA`) porque este proyecto también sirve como base de aprendizaje de esa arquitectura, aunque el dominio inicial sea pequeño.

## Stack base
- UI: `SwiftUI`
- Estado y composición: `The Composable Architecture`
- Concurrencia: `Swift Concurrency`
- Networking: `URLSession`
- Gráficas: `Charts`
- Notificaciones: `UserNotifications`
- Persistencia ligera de preferencias: `UserDefaults` o `AppStorage`
- Persistencia estructurada e histórico: `pointfreeco/sqlite-data`

## Reglas operativas de plataforma
- Preferir `async/await` en networking, persistencia y efectos; evitar callbacks salvo que una API del sistema no ofrezca alternativa razonable.
- Evitar `UIKit` como patrón principal de UI.
- Solo introducir puentes con `UIKit` cuando una integración del sistema o una limitación real de `SwiftUI` lo haga imprescindible.
- Si aparece una integración obligatoria con `UIKit`, aislarla en el borde de la feature correspondiente.
- Usar inglés para todo identificador de código; reservar el español para copy visible al usuario.

## Política de dependencias
- Regla general: Apple-first.
- Dependencia externa aprobada en el alcance base: `pointfreeco/swift-composable-architecture`.
- Dependencia externa aprobada en el alcance base: `pointfreeco/sqlite-data`.
- Motivo de la excepción para `TCA`:
  - el proyecto se usará también para aprender y practicar esta arquitectura,
  - aporta una estructura consistente basada en `State`, `Action`, `Reducer` y `Store`,
  - mejora la composición por features, efectos y testing desde el principio.
- Motivo de la excepción para `sqlite-data`:
  - persiste histórico local de `30 días` sin inventar una capa propia de almacenamiento,
  - encaja bien con un modelo local-first,
  - permite crecimiento posterior sin comprometer la UI inicial.
- No introducir nuevas dependencias sin una justificación concreta de producto o mantenimiento.

## Principios de TCA para este proyecto
- Cada feature debe modelarse con `State`, `Action` y `Reducer`.
- La UI debe recibir `StoreOf<Feature>` o el scope equivalente; evitar `ObservableObject` y `ViewModel` ad hoc como patrón principal.
- Los efectos asíncronos deben expresarse desde el reducer.
- Las dependencias de red, persistencia, notificaciones y fecha deben inyectarse mediante el sistema de dependencias de TCA.
- Los flujos importantes deben poder probarse con `TestStore`.
- La composición debe hacerse por feature y no por capas globales monolíticas.

## Organización lógica mínima

### 1. Datos de precios
Responsabilidades:
- Descargar y transformar datos `ESIOS/PVPC`.
- Persistir el día actual y el histórico de `30 días`.
- Exponer resúmenes diarios, precios horarios y clasificación relativa.

Entradas:
- respuesta de red,
- caché local persistida,
- fecha actual en zona horaria local.

Salidas:
- precios por hora,
- resumen del día,
- histórico para consultas y futura comparación.

### 2. Notificaciones
Responsabilidades:
- Solicitar permisos locales.
- Construir avisos del mínimo, máximo y umbral.
- Reprogramar avisos al cargar los datos del día.

Restricciones:
- Solo notificaciones locales.
- Solo horas futuras del mismo día.
- Sin `APS`, sin backend, sin sincronización remota.

### 3. Settings
Responsabilidades:
- Guardar flags de notificaciones.
- Guardar el umbral personalizado.
- Exponer estado legible para la UI.

### 4. Cálculo de coste
Responsabilidades:
- Resolver presets cerrados.
- Calcular coste estimado desde hora seleccionada y duración.
- Formatear resultado listo para UI.

### 5. Presentación/UI
Responsabilidades:
- Tabs principales.
- Cards de resumen.
- Lista horaria.
- Modal de cálculo.
- Gráfica segmentada por tramos.
- Pantalla de ajustes.

## Estructura recomendada por features

### `AppFeature`
- Coordina el `TabView` principal.
- Mantiene el estado de navegación raíz.
- Hace `scope` a `PricesFeature`, `ChartFeature` y `SettingsFeature`.

### `PricesFeature`
- Gestiona resumen diario, lista horaria y selección de franja.
- Presenta el modal de cálculo con estado hijo.

### `CostCalculationFeature`
- Gestiona preset elegido, duración y resultado del cálculo.
- Recibe la hora/precio seleccionados desde `PricesFeature`.

### `ChartFeature`
- Gestiona el tramo activo del día y los datos necesarios para la gráfica.

### `SettingsFeature`
- Gestiona permisos, toggles de notificación y umbral personalizado.

### Dependencias de dominio
- `PricingClient`: obtención y transformación de datos `ESIOS/PVPC`.
- `PersistenceClient`: lectura y escritura del histórico local mediante `sqlite-data`.
- `NotificationClient`: autorización y programación de avisos locales.
- `DateClient` o dependencia equivalente: fecha/hora actual y calendario.

## Tipos de dominio que deben existir

### `HourlyPrice`
- `date`: fecha-hora exacta de la franja.
- `priceEURPerKWh`: valor en `€/kWh`.
- `classification`: `cheap | mid | expensive`.
- `daypart`: `overnight | morning | afternoon | night`.
- `isCurrentHour`: marca opcional derivada para presentación.

### `PriceSummary`
- `current`: precio actual si existe.
- `average`: media del día.
- `minimum`: precio mínimo del día.
- `minimumHour`: hora del mínimo.
- `maximum`: precio máximo del día.
- `maximumHour`: hora del máximo.

### `AppliancePreset`
- `id`
- `kind`
- `powerKW`
- `symbolName`
- `displayNameKey`
- `shortDescriptionKey`

Valores base v1:
- `washer`, `washer`, `2.0`, `washer`, `appliance.washer.title`, `appliance.washer.description`
- `cooktop`, `cooktop`, `1.8`, `frying.pan`, `appliance.cooktop.title`, `appliance.cooktop.description`
- `airConditioner`, `airConditioner`, `1.2`, `wind`, `appliance.air_conditioner.title`, `appliance.air_conditioner.description`

### `CostCalculation`
- `selectedHour`
- `preset`
- `durationHours`
- `priceApplied`
- `estimatedCostEUR`

### `NotificationSettings`
- `notificationsEnabled`
- `notifyDailyMinimum`
- `notifyDailyMaximum`
- `customThresholdEnabled`
- `customThresholdEURPerKWh`

### `Daypart`
- `overnight`: `00:00-05:59`
- `morning`: `06:00-11:59`
- `afternoon`: `12:00-17:59`
- `night`: `18:00-23:59`

## Flujo de datos recomendado
1. Al iniciar o al refrescar, la app obtiene el precio del día.
2. La capa de datos persiste el día actual y poda el histórico a `30 días`.
3. Se recalculan `HourlyPrice`, `PriceSummary` y agrupaciones por `Daypart`.
4. La capa de notificaciones reconstruye las solicitudes locales para el resto del día.
5. El reducer raíz distribuye estado y acciones a cada feature.
6. La UI observa `Store`s scopiados y renderiza sin lógica pesada en vistas.

## Decisiones de implementación
- Preferir reducers pequeños y composables por feature en vez de una capa global masiva.
- Mantener la lógica de clasificación, resumen y scheduling fuera de la vista.
- Centralizar formateadores de moneda, energía y hora para evitar inconsistencias.
- Preparar los textos para localización, aunque la primera UI salga en español.
- Usar `@Dependency` para clientes de red, persistencia, calendario y notificaciones.
- Reservar `@ObservableState` al modelo de estado de TCA en vez de mezclar varios patrones de observación.

## Estrategia de persistencia
- `sqlite-data` guarda:
  - precios horarios,
  - resúmenes diarios materializados o derivables,
  - metadatos básicos de sincronización local.
- `UserDefaults` o `AppStorage` guardan:
  - settings de notificación,
  - umbral personalizado,
  - preferencias ligeras de UI si aparecen.

## Estrategia de pruebas
- Unit tests para:
  - clasificación relativa del día,
  - resumen diario,
  - asignación de `Daypart`,
  - cálculo de coste,
  - construcción de notificaciones,
  - poda del histórico a `30 días`.
- Tests de reducers con `TestStore` para:
  - carga del día actual,
  - apertura y cierre del modal de cálculo,
  - cambio de tramo en la gráfica,
  - toggles y persistencia de ajustes,
  - programación de efectos y respuestas de dependencias.
- Tests de integración para:
  - parsing y transformación de `ESIOS/PVPC`,
  - persistencia y lectura de caché.
- Tests de UI cuando la base del proyecto exista para tabs, modal y pantalla de ajustes.

## Fuera de alcance base
- `APS` remotas.
- Backend propio.
- Cuenta de usuario o sincronización en nube.
- Soporte iPad, macOS, watchOS o widgets en esta primera documentación.
- Configuración manual de franjas horarias.
- Cálculo libre sin preset como flujo principal.
