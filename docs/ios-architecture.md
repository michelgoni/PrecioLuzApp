# iOS Architecture

## Resumen técnico
La app se construye como una base `iPhone-first` en `iOS 26+`, con `SwiftUI` y APIs modernas de Apple. La arquitectura favorece lectura clara, cambios pequeños y validación frecuente en simulador. La gestión de estado y composición se apoya en `The Composable Architecture` (`TCA`) para mantener features pequeñas, efectos explícitos y testing desde el arranque.

## Estado actual del repositorio
- El repositorio sigue en fase documental y de planificación.
- La estructura de carpetas descrita aquí es una propuesta de implementación acordada, no una materialización existente en el árbol.
- Todavía no hay proyecto Xcode, código fuente de la app ni CI operativa en el repo.
- La implementación funcional de producto sigue pendiente por hitos y debe llegar por `Pull Request`.

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
- No introducir nuevas dependencias sin una justificación concreta de producto o mantenimiento.

## Principios de TCA para este proyecto
- Cada feature debe modelarse con `State`, `Action` y `Reducer`.
- La UI debe recibir `StoreOf<Feature>` o el scope equivalente; evitar `ObservableObject` y `ViewModel` ad hoc como patrón principal.
- Los efectos asíncronos deben expresarse desde el reducer.
- Las dependencias de red, persistencia, notificaciones y fecha deben inyectarse mediante el sistema de dependencias de TCA.
- Los flujos importantes deben poder probarse con `TestStore`.
- La composición debe hacerse por feature y no por capas globales monolíticas.

## Estructura de proyecto documentada

### `App`
- Punto de entrada de la app, composición raíz, lifecycle y montaje del `Store` principal.
- No contiene lógica de negocio específica de features.
- Esta carpeta no existe todavía; se creará cuando arranque el bootstrap real del proyecto iOS.

### `Features`
- Contenedor de features verticales del producto.
- Cada subcarpeta agrupa `State`, `Action`, `Reducer`, `View` y wiring mínimo de una capacidad concreta.
- La organización es por vertical funcional, no por capas técnicas.

### `Features/AppFeature`
- Orquestación raíz del `TabView`, selección de tab y scopes hacia features hijas.
- No debe absorber lógica de dominio específica.

### `Features/PricesFeature`
- Estado y UI del tab `Precios`: cards de resumen, lista horaria, selección de franja y apertura del flujo de cálculo.

### `Features/CostCalculationFeature`
- Flujo aislado del modal de cálculo: preset, duración y resultado.
- Recibe la franja seleccionada desde `PricesFeature`.

### `Features/ChartFeature`
- Estado y UI del tab `Gráfica`: tramo activo, datos filtrados y estado de inspección del gráfico.

### `Features/SettingsFeature`
- Estado y UI del tab `Ajustes`: permisos, toggles, umbral y sincronización con preferencias/notificaciones.

### `Domain`
- Modelos y reglas puras del negocio: `HourlyPrice`, `PriceSummary`, `Daypart`, `AppliancePreset`, `CostCalculation`, `NotificationSettings`.
- Sin dependencias de UI ni detalles de infraestructura.

### `Clients`
- Interfaces inyectables y variantes `live`, `test` y `preview` de dependencias externas.
- Aquí viven `PricingClient`, `PersistenceClient`, `NotificationClient` y `DateClient`.

### `Persistence`
- Modelado de almacenamiento local con `sqlite-data`, mapeos persistentes, repositorios locales y poda del histórico.
- No debe contener presentación ni reducers de UI.

### `UIShared`
- Componentes `SwiftUI` reutilizables, estilo visual, formateadores y utilidades de presentación comunes.
- Solo reutilización real; evitar meter aquí vistas de feature disfrazadas de genéricas.

### `Resources`
- Assets, strings y recursos estáticos de la app.
- Preparado para español inicial y localización futura.

### `Tests`
- Tests unitarios, de reducers e integración ligera.
- Estructura paralela por dominio/feature para que cada área pruebe su comportamiento sin ambigüedad.
- Esta carpeta queda definida a nivel de diseño, pero no debe materializarse hasta que se abra el hito de bootstrap técnico.

## Organización lógica mínima

### 1. Datos de precios
Responsabilidades:
- descargar y transformar datos `ESIOS/PVPC`
- persistir el día actual y el histórico de `30 días`
- exponer resúmenes diarios, precios horarios y clasificación relativa

### 2. Notificaciones
Responsabilidades:
- solicitar permisos locales
- construir avisos del mínimo, máximo y umbral
- reprogramar avisos al cargar los datos del día

### 3. Settings
Responsabilidades:
- guardar flags de notificaciones
- guardar el umbral personalizado
- exponer estado legible para la UI

### 4. Cálculo de coste
Responsabilidades:
- resolver presets cerrados
- calcular coste estimado desde hora seleccionada y duración
- formatear resultado listo para UI

### 5. Presentación/UI
Responsabilidades:
- tabs principales
- cards de resumen
- lista horaria
- flujo de cálculo
- gráfica segmentada por tramos
- pantalla de ajustes

## Features raíz recomendadas

### `AppFeature`
- coordina el `TabView` principal
- mantiene el estado de navegación raíz
- hace `scope` a `PricesFeature`, `ChartFeature` y `SettingsFeature`

### `PricesFeature`
- gestiona resumen diario, lista horaria y selección de franja
- presenta el flujo de cálculo con estado hijo

### `CostCalculationFeature`
- gestiona preset elegido, duración y resultado del cálculo
- recibe la hora/precio seleccionados desde `PricesFeature`

### `ChartFeature`
- gestiona el tramo activo del día y los datos necesarios para la gráfica

### `SettingsFeature`
- gestiona permisos, toggles de notificación y umbral personalizado

## Dependencias de dominio
- `PricingClient`: obtención y transformación de datos `ESIOS/PVPC`
- `PersistenceClient`: lectura y escritura del histórico local mediante `sqlite-data`
- `NotificationClient`: autorización y programación de avisos locales
- `DateClient`: fecha y calendario del sistema

## Tipos de dominio que deben existir

### `HourlyPrice`
- `date`: fecha-hora exacta de la franja
- `priceEURPerKWh`: valor en `€/kWh`
- `classification`: `cheap | mid | expensive`
- `daypart`: `overnight | morning | afternoon | night`
- `isCurrentHour`: marca derivada para presentación

### `PriceSummary`
- `current`: precio actual si existe
- `average`: media del día
- `minimum`: precio mínimo del día
- `minimumHour`: hora del mínimo
- `maximum`: precio máximo del día
- `maximumHour`: hora del máximo

### `AppliancePreset`
- `kind`
- `powerKW`
- `symbolName`
- `displayName`
- `shortDescription`

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
- Usar `@Dependency` o `DependencyValues` para clientes de red, persistencia, calendario y notificaciones.

## Estrategia de persistencia
- `sqlite-data` guardará:
  - precios horarios
  - snapshots diarios
  - metadatos básicos de sincronización local
- `UserDefaults` o `AppStorage` guardarán:
  - settings de notificación
  - umbral personalizado
  - preferencias ligeras de UI si aparecen

## Estrategia de pruebas
- Unit tests para:
  - clasificación relativa del día
  - resumen diario
  - asignación de `Daypart`
  - cálculo de coste
  - construcción de notificaciones
  - poda del histórico a `30 días`
- Tests de reducers con `TestStore` para:
  - carga del día actual
  - apertura y cierre del flujo de cálculo
  - cambio de tramo en la gráfica
  - toggles y persistencia de ajustes
  - programación de efectos y respuestas de dependencias
- Tests de integración para:
  - parsing y transformación de `ESIOS/PVPC`
  - persistencia y lectura de caché
- Tests de UI cuando la base del proyecto exista para tabs, cálculo y pantalla de ajustes

## Fuera de alcance base
- `APS` remotas
- backend propio
- cuenta de usuario o sincronización en nube
- soporte `iPad`, `macOS`, `watchOS` o widgets en esta primera fase
- configuración manual de franjas horarias
- cálculo libre sin preset como flujo principal
