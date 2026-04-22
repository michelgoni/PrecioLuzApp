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
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.selectedTabChanged(.settings)) {
            $0.selectedTab = .settings
        }
    }

    @MainActor
    @Test("AppFeature sets loading on onAppear")
    func onAppearSetsLoading() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.dateClient.now = { testNow }
            $0.dateClient.timeZone = { testTimeZone }
        }
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.rootStatus = .loading
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
            $0.prices.summary = payload.summary
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
            $0.prices.summary = payload.summary
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
        }
    }

    @MainActor
    @Test("AppFeature maps empty fresh snapshot to empty")
    func emptyFreshMapsToEmpty() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(.mockPayload(withPrices: false)))) {
            $0.rootStatus = .empty
            $0.prices.hourlyPrices = []
            $0.prices.isFromCache = false
            $0.prices.summary = nil
        }
    }

    @Test("App tabs expose expected SF Symbols")
    func tabSymbolsAreConfigured() {
        #expect(AppTab.chart.systemImage == "chart.xyaxis.line")
        #expect(AppTab.prices.systemImage == "eurosign.circle")
        #expect(AppTab.settings.systemImage == "gearshape")
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
}
