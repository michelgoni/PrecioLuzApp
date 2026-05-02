import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import PrecioLuzApp

@MainActor
struct Issue11SnapshotTests {
    private let isCI: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["CI"] == "true" || environment["GITHUB_ACTIONS"] == "true"
    }()
    private let snapshotLocale = Locale(identifier: "es_ES")
    private let snapshotTimeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt

    @Test("Snapshot #11: root status banner states remain visually stable")
    func rootStatusBannerStates() {
        guard !isCI else {
            return
        }
        let container = VStack(spacing: 12) {
            RootStatusBanner(onRetry: {}, status: .loading)
            RootStatusBanner(onRetry: {}, status: .cached)
            RootStatusBanner(onRetry: {}, status: .error)
        }
        .padding()
        .background(Color(.systemBackground))

        assertSnapshot(
            of: applySnapshotEnvironment(to: container),
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                layout: .device(config: .iPhoneSe)
            )
        )
    }

    @Test("Snapshot #11: prices summary and hourly list remain visually stable")
    func pricesContent() {
        guard !isCI else {
            return
        }
        let view = PricesView(
            onHourTapped: { _ in },
            state: .snapshotContent
        )

        assertSnapshot(
            of: applySnapshotEnvironment(to: view),
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                layout: .device(config: .iPhoneSe)
            )
        )
    }

    @Test("Snapshot #11: settings denied and authorized states remain visually stable")
    func settingsStates() {
        guard !isCI else {
            return
        }
        let deniedStore = Store(
            initialState: SettingsFeature.State(
                authorizationStatus: .denied,
                notificationSettings: .productDefaults
            )
        ) {
            SettingsFeature()
        }
        let authorizedSettings = NotificationSettings(
            customThresholdEnabled: true,
            customThresholdEURPerKWh: 0.150,
            notificationsEnabled: true,
            notifyDailyMaximum: true,
            notifyDailyMinimum: true
        )
        let authorizedStore = Store(
            initialState: SettingsFeature.State(
                authorizationStatus: .authorized,
                notificationSettings: authorizedSettings
            )
        ) {
            SettingsFeature()
        }

        let container = VStack(spacing: 16) {
            SettingsView(store: deniedStore)
                .frame(height: 360)
            SettingsView(store: authorizedStore)
                .frame(height: 360)
        }
        .padding()
        .background(Color(.systemBackground))

        assertSnapshot(
            of: applySnapshotEnvironment(to: container),
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                layout: .device(config: .iPhoneSe)
            )
        )
    }

    private func applySnapshotEnvironment<Content: View>(to view: Content) -> some View {
        view
            .environment(\.locale, snapshotLocale)
            .environment(\.timeZone, snapshotTimeZone)
    }
}

private extension PricesFeature.State {
    static var snapshotContent: Self {
        let prices = [
            HourlyPrice(
                classification: .cheap,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                daypart: .morning,
                eurPerKWh: 0.10
            ),
            HourlyPrice(
                classification: .mid,
                date: Date(timeIntervalSince1970: 1_700_003_600),
                daypart: .morning,
                eurPerKWh: 0.158
            ),
            HourlyPrice(
                classification: .expensive,
                date: Date(timeIntervalSince1970: 1_700_007_200),
                daypart: .afternoon,
                eurPerKWh: 0.215
            )
        ]
        return PricesFeature.State(
            costCalculation: CostCalculationFeature.State(),
            hourlyPrices: prices,
            isFromCache: false,
            isLoading: false,
            summary: PriceSummary(
                average: 0.158,
                current: prices[1],
                maximum: 0.215,
                maximumHour: prices[2].date,
                minimum: 0.10,
                minimumHour: prices[0].date
            )
        )
    }
}
