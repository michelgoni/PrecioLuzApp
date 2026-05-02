import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

private let testNow = Date(timeIntervalSince1970: 1_700_000_000)
private let testTimeZone = TimeZone(secondsFromGMT: .zero) ?? .current

struct AppFeatureTests {
    @MainActor
    @Test("AppFeature sets selected tab")
    func selectedTabChanged() async {
        var initialState = AppFeature.State()
        initialState.prices.costCalculation.isPresented = true
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.selectedTabChanged(.settings)) {
            $0.prices.costCalculation.isPresented = false
            $0.selectedTab = .settings
        }
    }

    @MainActor
    @Test("AppFeature sets loading on onAppear")
    func onAppearSetsLoading() async {
        var initialState = AppFeature.State()
        initialState.chart.inspectedHour = HourlyPrice.mockValue
        initialState.prices.costCalculation.isPresented = true
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
        }
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.chart.inspectedHour = nil
            $0.prices.costCalculation.isPresented = false
            $0.rootStatus = .loading
        }
    }

    @MainActor
    @Test("AppFeature keeps latest snapshot response as source of truth")
    func latestSnapshotResponseWins() async {
        let stalePayload = DailyPricingSnapshotPayload(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: [HourlyPrice.mockValue],
            summary: nil
        )
        let latestPayload = DailyPricingSnapshotPayload(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: [HourlyPrice.mockFutureValue],
            summary: nil
        )
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.failed)) {
            $0.rootStatus = .error
            $0.prices.isLoading = false
        }
        await store.send(.snapshotResponse(.fresh(stalePayload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = stalePayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(stalePayload.hourlyPrices))) {
            $0.chart.hourlyPrices = stalePayload.hourlyPrices
        }
        await store.send(.snapshotResponse(.fresh(latestPayload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = latestPayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(latestPayload.hourlyPrices))) {
            $0.chart.hourlyPrices = latestPayload.hourlyPrices
        }
    }

    @MainActor
    @Test("AppFeature updates chart daypart when chart action is sent")
    func chartDaypartChangedUpdatesState() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.chart(.selectedDaypartChanged(.night))) {
            $0.chart.selectedDaypart = .night
        }
    }

    @MainActor
    @Test("AppFeature updates chart inspection when chart action is sent")
    func chartInspectionChangedUpdatesState() async {
        let inspected = HourlyPrice.mockValue
        var initialState = AppFeature.State()
        initialState.chart.hourlyPrices = [inspected]
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.chart(.inspectedHourChanged(inspected))) {
            $0.chart.inspectedHour = inspected
        }
    }

    @MainActor
    @Test("AppFeature maps fresh snapshot to content")
    func freshMapsToContent() async {
        let payload = DailyPricingSnapshotPayload.mockPayload(withPrices: true)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }
    }

    @MainActor
    @Test("AppFeature maps cached snapshot to cached")
    func cachedMapsToCached() async {
        let payload = DailyPricingSnapshotPayload.mockPayload(withPrices: true)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.cached(payload))) {
            $0.rootStatus = .cached
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = true
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }
    }

    @MainActor
    @Test("AppFeature clears selected hour when snapshot no longer contains it")
    func snapshotResponseClearsStaleSelectedHour() async {
        let selectedHour = HourlyPrice.mockValue
        var initialState = AppFeature.State()
        initialState.prices.costCalculation.selectedHour = selectedHour
        let payload = DailyPricingSnapshotPayload(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: [HourlyPrice.mockFutureValue],
            summary: nil
        )
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.costCalculation.selectedHour = nil
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }
    }

    @MainActor
    @Test("AppFeature syncs snapshot hourly prices into ChartFeature")
    func snapshotResponseSyncsChartHourlyPrices() async {
        let payload = DailyPricingSnapshotPayload.mockPayload(withPrices: true)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }
    }

    @MainActor
    @Test("AppFeature clears stale chart inspection when refreshed prices no longer include it")
    func snapshotResponseClearsStaleChartInspection() async {
        let inspected = HourlyPrice.mockValue
        let replacement = HourlyPrice.mockFutureValue
        var initialState = AppFeature.State()
        initialState.chart.inspectedHour = inspected
        initialState.chart.hourlyPrices = [inspected]
        let refreshedPayload = DailyPricingSnapshotPayload(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: [replacement],
            summary: nil
        )
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(refreshedPayload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = refreshedPayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(refreshedPayload.hourlyPrices))) {
            $0.chart.hourlyPrices = refreshedPayload.hourlyPrices
            $0.chart.inspectedHour = nil
        }
    }

    @MainActor
    @Test("AppFeature refreshes inspected hour value when same date remains after sync")
    func snapshotResponseRefreshesInspectedHourForSameDate() async {
        let inspectedDate = Date(timeIntervalSince1970: 1_700_123_200)
        let inspected = HourlyPrice(
            classification: .mid,
            date: inspectedDate,
            daypart: .morning,
            eurPerKWh: 0.19
        )
        let refreshed = HourlyPrice(
            classification: .expensive,
            date: inspectedDate,
            daypart: .morning,
            eurPerKWh: 0.27
        )

        var initialState = AppFeature.State()
        initialState.chart.selectedDaypart = .morning
        initialState.chart.hourlyPrices = [inspected]
        initialState.chart.inspectedHour = inspected

        let refreshedPayload = DailyPricingSnapshotPayload(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: [refreshed],
            summary: nil
        )
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(refreshedPayload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = refreshedPayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(refreshedPayload.hourlyPrices))) {
            $0.chart.hourlyPrices = refreshedPayload.hourlyPrices
            $0.chart.inspectedHour = refreshed
        }
    }

    @MainActor
    @Test("AppFeature maps failed result to error")
    func failedMapsToError() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.failed)) {
            $0.rootStatus = .error
            $0.prices.isLoading = false
        }
    }

    @MainActor
    @Test("AppFeature maps empty fresh snapshot to empty")
    func emptyFreshMapsToEmpty() async {
        let payload = DailyPricingSnapshotPayload.mockPayload(withPrices: false)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .empty
            $0.prices.hourlyPrices = []
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices)))
    }

    @MainActor
    @Test("AppFeature opens calculation modal when an hourly price is selected")
    func pricesHourTappedPresentsCalculationModal() async {
        let selectedHour = HourlyPrice.mockValue
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.pricesHourTapped(selectedHour)) {
            $0.prices.costCalculation.durationHours = CostCalculationFeature.State.defaultDurationHours
            $0.prices.costCalculation.isPresented = true
            $0.prices.costCalculation.selectedHour = selectedHour
            $0.prices.costCalculation.selectedPresetKind = .washingMachine
        }
    }

    @MainActor
    @Test("AppFeature closes calculation modal when dismiss is triggered")
    func pricesCalculationPlaceholderDismissedClosesModal() async {
        var initialState = AppFeature.State()
        initialState.prices.costCalculation.isPresented = true
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.pricesCalculationPlaceholderDismissed) {
            $0.prices.costCalculation.isPresented = false
        }
    }

    @MainActor
    @Test("AppFeature applies loaded notification settings")
    func notificationSettingsLoadedUpdatesState() async {
        let loadedSettings = NotificationSettings(
            customThresholdEnabled: true,
            customThresholdEURPerKWh: 0.225,
            notificationsEnabled: true,
            notifyDailyMaximum: true,
            notifyDailyMinimum: false
        )
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.notificationSettingsLoaded(loadedSettings)) {
            $0.settings.notificationSettings = loadedSettings
        }
    }

    @MainActor
    @Test("AppFeature sanitizes loaded settings when authorization is denied")
    func notificationSettingsLoadedStaysDisabledWhenAuthorizationIsDenied() async {
        let requestsRecorder = NotificationRequestsRecorder()
        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .denied

        let loadedSettings = NotificationSettings(
            customThresholdEnabled: true,
            customThresholdEURPerKWh: 0.20,
            notificationsEnabled: true,
            notifyDailyMaximum: true,
            notifyDailyMinimum: true
        )

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
            $0.notificationClient.schedule = { requests in
                await requestsRecorder.record(requests)
            }
        }

        await store.send(.notificationSettingsLoaded(loadedSettings)) {
            $0.settings.notificationSettings = NotificationSettings(
                customThresholdEnabled: true,
                customThresholdEURPerKWh: 0.20,
                notificationsEnabled: false,
                notifyDailyMaximum: true,
                notifyDailyMinimum: true
            )
        }
        await store.finish()

        let scheduledRequests = await requestsRecorder.last
        #expect(scheduledRequests.isEmpty)
    }

    @MainActor
    @Test("AppFeature reschedules notifications when persisted settings load after snapshot")
    func notificationSettingsLoadedReschedulesAfterSnapshot() async {
        let requestsRecorder = NotificationRequestsRecorder()
        let payload = DailyPricingSnapshotPayload(
            dayStart: testNow,
            fetchedAt: testNow,
            hourlyPrices: [HourlyPrice.mockFutureValue],
            summary: nil
        )

        let loadedSettings = NotificationSettings(
            customThresholdEnabled: false,
            customThresholdEURPerKWh: nil,
            notificationsEnabled: true,
            notifyDailyMaximum: false,
            notifyDailyMinimum: true
        )

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
            $0.notificationClient.schedule = { requests in
                await requestsRecorder.record(requests)
            }
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }

        await store.send(.notificationSettingsLoaded(loadedSettings)) {
            $0.settings.notificationSettings = loadedSettings
        }
        await store.finish()

        let scheduledRequests = await requestsRecorder.last
        #expect(scheduledRequests.count == 1)
        #expect(scheduledRequests.first?.id.contains("dailyMinimum") == true)
    }

    @MainActor
    @Test("AppFeature persists notification settings after settings changes")
    func settingsActionSavesNotificationSettings() async {
        let recorder = NotificationSettingsRecorder()
        let requestsRecorder = NotificationRequestsRecorder()
        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .authorized
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
            $0.notificationClient.schedule = { requests in
                await requestsRecorder.record(requests)
            }
            $0.persistenceClient.loadNotificationSettings = { nil }
            $0.persistenceClient.saveNotificationSettings = { settings in
                await recorder.record(settings)
            }
        }

        await store.send(.settings(.notificationsEnabledChanged(true))) {
            $0.settings.notificationSettings.notificationsEnabled = true
        }
        await store.finish()

        let savedSettings = await recorder.last
        let scheduledRequests = await requestsRecorder.last
        #expect(savedSettings == store.state.settings.notificationSettings)
        #expect(scheduledRequests.isEmpty)
    }

    @MainActor
    @Test("AppFeature reschedules notifications when snapshot is refreshed")
    func snapshotResponseReschedulesNotifications() async {
        let requestsRecorder = NotificationRequestsRecorder()
        var initialState = AppFeature.State()
        initialState.settings.notificationSettings.notificationsEnabled = true
        initialState.settings.notificationSettings.notifyDailyMinimum = true
        initialState.settings.notificationSettings.notifyDailyMaximum = false

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
            $0.notificationClient.schedule = { requests in
                await requestsRecorder.record(requests)
            }
        }

        let payload = DailyPricingSnapshotPayload(
            dayStart: testNow,
            fetchedAt: testNow,
            hourlyPrices: [
                HourlyPrice(
                    classification: .mid,
                    date: testNow.addingTimeInterval(3_600),
                    daypart: .morning,
                    eurPerKWh: 0.18
                ),
                HourlyPrice(
                    classification: .cheap,
                    date: testNow.addingTimeInterval(7_200),
                    daypart: .morning,
                    eurPerKWh: 0.11
                ),
            ],
            summary: nil
        )

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.rootStatus = .content
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = nil
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }
        await store.finish()

        let scheduledRequests = await requestsRecorder.last
        #expect(scheduledRequests.count == 1)
        #expect(scheduledRequests.first?.id.contains("dailyMinimum") == true)
    }

    @MainActor
    @Test("AppFeature enables notifications immediately when authorization is authorized")
    func notificationsEnabledWhenAuthorized() async {
        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .authorized
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.settings(.notificationsEnabledChanged(true))) {
            $0.settings.notificationSettings.notificationsEnabled = true
        }
    }

    @MainActor
    @Test("AppFeature keeps notifications disabled when authorization is denied")
    func notificationsStayDisabledWhenDenied() async {
        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .denied
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.settings(.notificationsEnabledChanged(true)))
        #expect(store.state.settings.notificationSettings.notificationsEnabled == false)
    }

    @MainActor
    @Test("AppFeature requests permission when authorization is not determined")
    func notificationsRequestPermissionWhenNotDetermined() async {
        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .notDetermined
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.notificationClient.requestAuthorization = { true }
        }

        await store.send(.settings(.notificationsEnabledChanged(true)))
        await store.receive(.notificationPermissionRequestFinished(true)) {
            $0.settings.authorizationStatus = .authorized
            $0.settings.notificationSettings.notificationsEnabled = true
        }
    }

    @MainActor
    @Test("AppFeature applies denied authorization status and forces notifications off")
    func authorizationStatusDeniedForcesNotificationsOff() async {
        var initialState = AppFeature.State()
        initialState.settings.notificationSettings.notificationsEnabled = true
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.notificationAuthorizationStatusLoaded(.denied)) {
            $0.settings.authorizationStatus = .denied
            $0.settings.notificationSettings.notificationsEnabled = false
        }
    }

    @MainActor
    @Test("AppFeature reloads authorization when app becomes active")
    func appDidBecomeActiveReloadsAuthorization() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.notificationClient.authorizationStatus = { .authorized }
        }

        await store.send(.appDidBecomeActive)
        await store.receive(.notificationAuthorizationStatusLoaded(.authorized)) {
            $0.settings.authorizationStatus = .authorized
        }
    }

    @MainActor
    @Test("AppFeature reloads authorization when open settings is tapped")
    func openSystemSettingsTappedReloadsAuthorization() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.notificationClient.authorizationStatus = { .authorized }
        }

        await store.send(.settings(.openSystemSettingsTapped))
        await store.receive(.notificationAuthorizationStatusLoaded(.authorized)) {
            $0.settings.authorizationStatus = .authorized
        }
    }

    @Test("App tabs expose expected SF Symbols")
    func tabSymbolsAreConfigured() {
        #expect(AppTab.chart.systemImage == "chart.xyaxis.line")
        #expect(AppTab.prices.systemImage == "eurosign.circle")
        #expect(AppTab.settings.systemImage == "gearshape")
    }
}

private actor NotificationSettingsRecorder {
    private(set) var last: NotificationSettings?

    func record(_ settings: NotificationSettings) {
        last = settings
    }
}

private actor NotificationRequestsRecorder {
    private(set) var last: [NotificationClient.Request] = []

    func record(_ requests: [NotificationClient.Request]) {
        last = requests
    }
}

private extension Date {
    static let mockNow = testNow
}

private extension DailyPricingSnapshotPayload {
    static func mockPayload(withPrices: Bool) -> Self {
        let prices = withPrices ? [HourlyPrice.mockValue] : []
        return .init(
            dayStart: .mockNow,
            fetchedAt: .mockNow,
            hourlyPrices: prices,
            summary: nil
        )
    }
}

private extension HourlyPrice {
    static let mockValue = HourlyPrice(
        classification: .cheap,
        date: .mockNow,
        daypart: .morning,
        eurPerKWh: 0.15
    )

    static let mockFutureValue = HourlyPrice(
        classification: .mid,
        date: Date.mockNow.addingTimeInterval(3_600),
        daypart: .morning,
        eurPerKWh: 0.18
    )
}
