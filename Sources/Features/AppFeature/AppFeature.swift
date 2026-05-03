import ComposableArchitecture
import Foundation

enum AppTab: Hashable {
    case chart
    case prices
    case settings

    var title: String {
        switch self {
        case .chart:
            String(localized: "tab.chart.title")
        case .prices:
            String(localized: "tab.prices.title")
        case .settings:
            String(localized: "tab.settings.title")
        }
    }

    var systemImage: String {
        switch self {
        case .chart:
            "chart.xyaxis.line"
        case .prices:
            "eurosign.circle"
        case .settings:
            "gearshape"
        }
    }
}

enum RootStatus: Equatable, Sendable {
    case cached
    case content
    case empty
    case error
    case loading
}

struct AppFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var chart = ChartFeature.State()
        var prices = PricesFeature.State()
        var rootStatus: RootStatus = .loading
        var selectedTab: AppTab = .prices
        var settings = SettingsFeature.State()
    }

    @CasePathable
    enum Action: Equatable {
        case appDidBecomeActive
        case chart(ChartFeature.Action)
        case notificationAuthorizationStatusLoaded(NotificationClient.AuthorizationStatus)
        case notificationPermissionRequestFinished(Bool)
        case notificationSettingsLoaded(NotificationSettings)
        case onAppear
        case pricesCalculationPlaceholderDismissed
        case pricesDurationHoursChanged(Double)
        case pricesHourTapped(HourlyPrice)
        case pricesPresetSelected(AppliancePreset.Kind)
        case retryTapped
        case selectedTabChanged(AppTab)
        case settings(SettingsFeature.Action)
        case snapshotResponse(DailyPricingSnapshotPipelineResult)
    }

    @Dependency(\.dateClient) var dateClient
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.pricingClient) var pricingClient

    private enum CancelID {
        case fetchAuthorizationStatus
        case loadSnapshot
        case loadSettings
        case requestNotificationPermission
        case rescheduleNotifications
        case saveSettings
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appDidBecomeActive:
                return loadNotificationAuthorizationStatusEffect()

            case let .chart(chartAction):
                applyChartAction(chartAction, to: &state.chart)
                return .none

            case .onAppear, .retryTapped:
                prepareForSnapshotLoad(&state)
                let loadEffects = Effect<Action>.merge(
                    loadNotificationAuthorizationStatusEffect(),
                    loadNotificationSettingsEffect(),
                    loadSnapshotEffect()
                )
                return .concatenate(
                    cancelInFlightEffects(),
                    loadEffects
                )

            case .pricesCalculationPlaceholderDismissed:
                state.prices.costCalculation.isPresented = false
                return .none

            case let .pricesDurationHoursChanged(durationHours):
                state.prices.costCalculation.durationHours = min(
                    max(durationHours, CostCalculationFeature.State.minimumDurationHours),
                    CostCalculationFeature.State.maximumDurationHours
                )
                return .none

            case let .pricesHourTapped(hour):
                guard state.prices.isVisibleHour(hour) else {
                    return .none
                }
                state.prices.costCalculation.durationHours = CostCalculationFeature.State.defaultDurationHours
                state.prices.costCalculation.selectedPresetKind = .washingMachine
                state.prices.costCalculation.selectedHour = hour
                state.prices.costCalculation.isPresented = true
                return .none

            case let .pricesPresetSelected(kind):
                state.prices.costCalculation.selectedPresetKind = kind
                return .none

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                if tab != .prices {
                    state.prices.costCalculation.isPresented = false
                }
                return .none

            case let .settings(settingsAction):
                return handleSettingsAction(settingsAction, state: &state)

            case let .notificationSettingsLoaded(notificationSettings):
                let sanitizedSettings = sanitizeLoadedSettings(
                    notificationSettings,
                    authorizationStatus: state.settings.authorizationStatus
                )
                state.settings.notificationSettings = sanitizedSettings

                var effects: [Effect<Action>] = [
                    rescheduleNotificationsEffect(
                        hourlyPrices: state.prices.hourlyPrices,
                        settings: sanitizedSettings
                    )
                ]

                if sanitizedSettings != notificationSettings {
                    effects.append(saveNotificationSettingsEffect(sanitizedSettings))
                }

                return .merge(effects)

            case let .notificationAuthorizationStatusLoaded(status):
                state.settings.authorizationStatus = status
                if status == .denied {
                    state.settings.notificationSettings.notificationsEnabled = false
                    return .merge(
                        saveNotificationSettingsEffect(state.settings.notificationSettings),
                        rescheduleNotificationsEffect(
                            hourlyPrices: state.prices.hourlyPrices,
                            settings: state.settings.notificationSettings
                        )
                    )
                }
                return .none

            case let .notificationPermissionRequestFinished(isGranted):
                state.settings.authorizationStatus = isGranted ? .authorized : .denied
                state.settings.notificationSettings.notificationsEnabled = isGranted
                return .merge(
                    saveNotificationSettingsEffect(state.settings.notificationSettings),
                    rescheduleNotificationsEffect(
                        hourlyPrices: state.prices.hourlyPrices,
                        settings: state.settings.notificationSettings
                    )
                )

            case let .snapshotResponse(result):
                state.rootStatus = mapRootStatus(from: result)
                updateFeatureStates(&state, from: result)
                return .merge(
                    chartSyncEffect(from: result),
                    scheduleNotificationsFromSnapshotEffect(
                        result: result,
                        settings: state.settings.notificationSettings
                    )
                )
            }
        }
    }

    private func applyChartAction(_ action: ChartFeature.Action, to state: inout ChartFeature.State) {
        switch action {
        case let .inspectedHourChanged(hour):
            state.inspectedHour = hour

        case let .selectedDaypartChanged(daypart):
            state.selectedDaypart = daypart
            if let inspectedHour = state.inspectedHour,
               !state.filteredPrices.contains(where: { $0.date == inspectedHour.date }) {
                state.inspectedHour = nil
            }

        case let .syncHourlyPrices(hourlyPrices):
            state.hourlyPrices = hourlyPrices
            if let inspectedDate = state.inspectedHour?.date {
                state.inspectedHour = state.filteredPrices.first { $0.date == inspectedDate }
            }
        }
    }

    private func applySettingsAction(_ action: SettingsFeature.Action, to state: inout SettingsFeature.State) {
        switch action {
        case let .notificationsEnabledChanged(isEnabled):
            state.notificationSettings.notificationsEnabled = isEnabled

        case let .notifyDailyMinimumChanged(isEnabled):
            guard state.notificationSettings.notificationsEnabled else {
                return
            }
            state.notificationSettings.notifyDailyMinimum = isEnabled

        case let .notifyDailyMaximumChanged(isEnabled):
            guard state.notificationSettings.notificationsEnabled else {
                return
            }
            state.notificationSettings.notifyDailyMaximum = isEnabled

        case let .customThresholdEnabledChanged(isEnabled):
            guard state.notificationSettings.notificationsEnabled else {
                return
            }
            state.notificationSettings.customThresholdEnabled = isEnabled

        case let .customThresholdEURPerKWhChanged(value):
            let clampedValue = min(
                max(value, SettingsFeature.State.minimumThresholdEURPerKWh),
                SettingsFeature.State.maximumThresholdEURPerKWh
            )
            let step = SettingsFeature.State.thresholdStepEURPerKWh
            state.notificationSettings.customThresholdEURPerKWh = (clampedValue / step).rounded() * step

        case .openSystemSettingsTapped:
            break
        }
    }

    private func cancelInFlightEffects() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.fetchAuthorizationStatus),
            .cancel(id: CancelID.loadSettings),
            .cancel(id: CancelID.loadSnapshot),
            .cancel(id: CancelID.requestNotificationPermission),
            .cancel(id: CancelID.rescheduleNotifications)
        )
    }

    private func chartSyncEffect(from result: DailyPricingSnapshotPipelineResult) -> Effect<Action> {
        switch result {
        case .failed:
            return .none
        case let .cached(payload), let .fresh(payload):
            return .send(.chart(.syncHourlyPrices(payload.hourlyPrices)))
        }
    }

    private func handleSettingsAction(_ action: SettingsFeature.Action, state: inout State) -> Effect<Action> {
        switch action {
        case .notificationsEnabledChanged(false):
            state.settings.notificationSettings.notificationsEnabled = false
            return .merge(
                saveNotificationSettingsEffect(state.settings.notificationSettings),
                rescheduleNotificationsEffect(
                    hourlyPrices: state.prices.hourlyPrices,
                    settings: state.settings.notificationSettings
                )
            )

        case .notificationsEnabledChanged(true):
            switch state.settings.authorizationStatus {
            case .authorized:
                state.settings.notificationSettings.notificationsEnabled = true
                return .merge(
                    saveNotificationSettingsEffect(state.settings.notificationSettings),
                    rescheduleNotificationsEffect(
                        hourlyPrices: state.prices.hourlyPrices,
                        settings: state.settings.notificationSettings
                    )
                )

            case .denied:
                state.settings.notificationSettings.notificationsEnabled = false
                return .merge(
                    saveNotificationSettingsEffect(state.settings.notificationSettings),
                    rescheduleNotificationsEffect(
                        hourlyPrices: state.prices.hourlyPrices,
                        settings: state.settings.notificationSettings
                    )
                )

            case .notDetermined:
                state.settings.notificationSettings.notificationsEnabled = false
                return requestNotificationPermissionEffect()
            }

        case .openSystemSettingsTapped:
            return loadNotificationAuthorizationStatusEffect()

        default:
            applySettingsAction(action, to: &state.settings)
            return .merge(
                saveNotificationSettingsEffect(state.settings.notificationSettings),
                rescheduleNotificationsEffect(
                    hourlyPrices: state.prices.hourlyPrices,
                    settings: state.settings.notificationSettings
                )
            )
        }
    }

    private func loadNotificationAuthorizationStatusEffect() -> Effect<Action> {
        .run { [notificationClient] send in
            let status = await notificationClient.authorizationStatus()
            await send(.notificationAuthorizationStatusLoaded(status))
        }
        .cancellable(id: CancelID.fetchAuthorizationStatus, cancelInFlight: true)
    }

    private func loadNotificationSettingsEffect() -> Effect<Action> {
        .run { [persistenceClient] send in
            let loadedSettings = try? await persistenceClient.loadNotificationSettings()
            await send(.notificationSettingsLoaded(loadedSettings ?? NotificationSettings.productDefaults))
        }
        .cancellable(id: CancelID.loadSettings, cancelInFlight: true)
    }

    private func loadSnapshotEffect() -> Effect<Action> {
        .run { [dateClient, persistenceClient, pricingClient] send in
            let pipeline = DailyPricingSnapshotPipeline(
                dateClient: dateClient,
                persistenceClient: persistenceClient,
                pricingClient: pricingClient
            )
            let result = await pipeline.load()
            await send(.snapshotResponse(result))
        }
        .cancellable(id: CancelID.loadSnapshot, cancelInFlight: true)
    }

    private func makeNotificationRequest(
        from planItem: NotificationSchedulingPlanner.PlanItem
    ) -> NotificationClient.Request {
        NotificationClient.Request(
            id: notificationIdentifier(for: planItem),
            title: notificationTitle(for: planItem.kind),
            body: notificationBody(for: planItem.kind),
            triggerDate: planItem.triggerDate
        )
    }

    private func mapRootStatus(from result: DailyPricingSnapshotPipelineResult) -> RootStatus {
        switch result {
        case .failed:
            .error
        case let .cached(payload):
            mapStatus(from: payload, whenNotEmpty: .cached)
        case let .fresh(payload):
            mapStatus(from: payload, whenNotEmpty: .content)
        }
    }

    private func mapStatus(from payload: DailyPricingSnapshotPayload, whenNotEmpty status: RootStatus) -> RootStatus {
        payload.hourlyPrices.isEmpty ? .empty : status
    }

    private func notificationBody(for kind: NotificationSchedulingPlanner.PlanItem.Kind) -> String {
        switch kind {
        case .dailyMaximum:
            String(localized: "notifications.dailyMaximum.body")
        case .dailyMinimum:
            String(localized: "notifications.dailyMinimum.body")
        case .threshold:
            String(localized: "notifications.threshold.body")
        }
    }

    private func notificationIdentifier(for planItem: NotificationSchedulingPlanner.PlanItem) -> String {
        let kindToken: String
        switch planItem.kind {
        case .dailyMaximum:
            kindToken = "dailyMaximum"
        case .dailyMinimum:
            kindToken = "dailyMinimum"
        case .threshold:
            kindToken = "threshold"
        }
        let timestampToken = Int(planItem.hour.date.timeIntervalSince1970)
        return "pricing.\(kindToken).\(timestampToken)"
    }

    private func notificationTitle(for kind: NotificationSchedulingPlanner.PlanItem.Kind) -> String {
        switch kind {
        case .dailyMaximum:
            String(localized: "notifications.dailyMaximum.title")
        case .dailyMinimum:
            String(localized: "notifications.dailyMinimum.title")
        case .threshold:
            String(localized: "notifications.threshold.title")
        }
    }

    private func prepareForSnapshotLoad(_ state: inout State) {
        state.rootStatus = .loading
        state.chart.inspectedHour = nil
        state.prices.costCalculation.isPresented = false
        state.prices.isLoading = true
    }

    private func requestNotificationPermissionEffect() -> Effect<Action> {
        .run { [notificationClient] send in
            let isGranted = (try? await notificationClient.requestAuthorization()) ?? false
            await send(.notificationPermissionRequestFinished(isGranted))
        }
        .cancellable(id: CancelID.requestNotificationPermission, cancelInFlight: true)
    }

    private func rescheduleNotificationsEffect(
        hourlyPrices: [HourlyPrice],
        settings: NotificationSettings
    ) -> Effect<Action> {
        .run { [dateClient, notificationClient] _ in
            let now = dateClient.now()
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = dateClient.timeZone()

            let plan = NotificationSchedulingPlanner.makePlan(
                hourlyPrices: hourlyPrices,
                settings: settings,
                now: now,
                calendar: calendar
            )
            let requests = plan.map(makeNotificationRequest(from:))
            try? await notificationClient.schedule(requests)
        }
        .cancellable(id: CancelID.rescheduleNotifications, cancelInFlight: true)
    }

    private func sanitizeLoadedSettings(
        _ settings: NotificationSettings,
        authorizationStatus: NotificationClient.AuthorizationStatus
    ) -> NotificationSettings {
        guard authorizationStatus == .denied else {
            return settings
        }
        var sanitizedSettings = settings
        sanitizedSettings.notificationsEnabled = false
        return sanitizedSettings
    }

    private func saveNotificationSettingsEffect(_ settings: NotificationSettings) -> Effect<Action> {
        .run { [persistenceClient] _ in
            try? await persistenceClient.saveNotificationSettings(settings)
        }
        .cancellable(id: CancelID.saveSettings, cancelInFlight: true)
    }

    private func scheduleNotificationsFromSnapshotEffect(
        result: DailyPricingSnapshotPipelineResult,
        settings: NotificationSettings
    ) -> Effect<Action> {
        switch result {
        case .failed:
            return .none
        case let .cached(payload), let .fresh(payload):
            return rescheduleNotificationsEffect(hourlyPrices: payload.hourlyPrices, settings: settings)
        }
    }

    private func updateFeatureStates(_ state: inout State, from result: DailyPricingSnapshotPipelineResult) {
        updatePricesState(&state.prices, from: result)
    }

    private func updatePricesState(
        _ state: inout PricesFeature.State,
        from result: DailyPricingSnapshotPipelineResult
    ) {
        switch result {
        case .failed:
            state.isLoading = false
        case let .cached(payload):
            state.applySnapshot(
                payload,
                isCached: true,
                now: dateClient.now(),
                calendar: currentCalendar()
            )
        case let .fresh(payload):
            state.applySnapshot(
                payload,
                isCached: false,
                now: dateClient.now(),
                calendar: currentCalendar()
            )
        }
    }

    private func currentCalendar() -> Calendar {
        var calendar = dateClient.calendar()
        calendar.timeZone = dateClient.timeZone()
        return calendar
    }
}
