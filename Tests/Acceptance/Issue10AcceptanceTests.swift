import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct Issue10AcceptanceTests {
    @MainActor
    @Test("Acceptance #10: settings changes trigger notification re-scheduling")
    func settingsChangesTriggerNotificationRescheduling() async {
        let scheduleRecorder = NotificationRequestsHistoryRecorder()
        let now = Self.referenceNow
        let payload = Self.makePayload(
            prices: [
                Self.makeHourlyPrice(hourOffset: 1, price: 0.11),
                Self.makeHourlyPrice(hourOffset: 2, price: 0.19),
                Self.makeHourlyPrice(hourOffset: 3, price: 0.23)
            ]
        )

        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .authorized

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { now }
            $0.dateClient.timeZone = { .gmt }
            $0.notificationClient.schedule = { requests in
                await scheduleRecorder.record(requests)
            }
            $0.persistenceClient.saveNotificationSettings = { _ in }
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.visibleHourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
            $0.rootStatus = .content
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }

        await store.send(.settings(.notificationsEnabledChanged(true))) {
            $0.settings.notificationSettings.notificationsEnabled = true
        }
        await store.send(.settings(.customThresholdEnabledChanged(true))) {
            $0.settings.notificationSettings.customThresholdEnabled = true
        }
        await store.send(.settings(.customThresholdEURPerKWhChanged(0.20))) {
            $0.settings.notificationSettings.customThresholdEURPerKWh = 0.20
        }
        await store.finish()

        let history = await scheduleRecorder.history
        let lastScheduled = history.last ?? []
        #expect(!history.isEmpty)
        #expect(!lastScheduled.isEmpty)
        #expect(lastScheduled.contains(where: { $0.id.contains("dailyMinimum") }))
        #expect(lastScheduled.contains(where: { $0.id.contains("threshold") }))
    }

    @MainActor
    @Test("Acceptance #10: denied authorization forces notifications off and clears scheduling")
    func deniedAuthorizationForcesNotificationsOffAndClearsScheduling() async {
        let scheduleRecorder = NotificationRequestsHistoryRecorder()
        let now = Self.referenceNow
        let payload = Self.makePayload(
            prices: [
                Self.makeHourlyPrice(hourOffset: 1, price: 0.11),
                Self.makeHourlyPrice(hourOffset: 2, price: 0.19)
            ]
        )

        var initialState = AppFeature.State()
        initialState.settings.authorizationStatus = .authorized
        initialState.settings.notificationSettings.notificationsEnabled = true

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { now }
            $0.dateClient.timeZone = { .gmt }
            $0.notificationClient.schedule = { requests in
                await scheduleRecorder.record(requests)
            }
            $0.persistenceClient.saveNotificationSettings = { _ in }
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.visibleHourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
            $0.rootStatus = .content
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }

        await store.send(.notificationAuthorizationStatusLoaded(.denied)) {
            $0.settings.authorizationStatus = .denied
            $0.settings.notificationSettings.notificationsEnabled = false
        }
        await store.finish()

        let lastScheduled = await scheduleRecorder.last
        #expect(lastScheduled.isEmpty)
    }
}

private actor NotificationRequestsHistoryRecorder {
    private(set) var history: [[NotificationClient.Request]] = []

    var last: [NotificationClient.Request] {
        history.last ?? []
    }

    func record(_ requests: [NotificationClient.Request]) {
        history.append(requests)
    }
}

private extension Issue10AcceptanceTests {
    static let referenceNow = Date(timeIntervalSince1970: 1_700_006_400) // midday UTC

    static func makeHourlyPrice(hourOffset: Int, price: Double) -> HourlyPrice {
        HourlyPrice(
            classification: .mid,
            date: referenceNow.addingTimeInterval(TimeInterval(hourOffset * 3_600)),
            daypart: .afternoon,
            eurPerKWh: price
        )
    }

    static func makePayload(prices: [HourlyPrice]) -> DailyPricingSnapshotPayload {
        let fallbackDate = prices.first?.date ?? referenceNow
        return DailyPricingSnapshotPayload(
            dayStart: Calendar(identifier: .gregorian).startOfDay(for: referenceNow),
            fetchedAt: referenceNow,
            hourlyPrices: prices,
            summary: PriceSummary(
                average: prices.reduce(0) { $0 + $1.eurPerKWh } / Double(prices.count),
                current: prices.first,
                maximum: prices.map(\.eurPerKWh).max() ?? 0,
                maximumHour: prices.max(by: { $0.eurPerKWh < $1.eurPerKWh })?.date ?? fallbackDate,
                minimum: prices.map(\.eurPerKWh).min() ?? 0,
                minimumHour: prices.min(by: { $0.eurPerKWh < $1.eurPerKWh })?.date ?? fallbackDate
            )
        )
    }
}
