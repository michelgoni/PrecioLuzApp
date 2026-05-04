import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct Issue11AcceptanceTests {
    @MainActor
    @Test("Acceptance #11: failed snapshot keeps root in error when cache is not available")
    func failedSnapshotWithoutCacheMapsToError() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.failed)) {
            $0.rootStatus = .error
            $0.prices.isLoading = false
        }
    }

    @MainActor
    @Test("Acceptance #11: cached snapshot keeps stale selections reconciled")
    func cachedSnapshotReconcilesStaleSelections() async {
        let staleHour = Self.hour(offset: 1, price: 0.31)
        let freshHour = Self.hour(offset: 2, price: 0.12)
        var initialState = AppFeature.State()
        initialState.chart.inspectedHour = staleHour
        initialState.chart.hourlyPrices = [staleHour]
        initialState.prices.costCalculation.isPresented = true
        initialState.prices.costCalculation.selectedHour = staleHour

        let payload = Self.payload(prices: [freshHour])
        let store = TestStore(initialState: initialState) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.cached(payload))) {
            $0.prices.costCalculation.isPresented = false
            $0.prices.costCalculation.selectedHour = nil
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.visibleHourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = true
            $0.prices.isLoading = false
            $0.prices.summary = payload.summary
            $0.rootStatus = .cached
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
            $0.chart.inspectedHour = nil
        }
    }

    @MainActor
    @Test("Acceptance #11: fresh snapshot after failure recovers to content")
    func freshSnapshotAfterFailureRecoversToContent() async {
        let payload = Self.payload(prices: [Self.hour(offset: 3, price: 0.14)])
        var initialState = AppFeature.State()
        initialState.rootStatus = .error

        let store = TestStore(initialState: initialState) {
            AppFeature()
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
    }
}

private extension Issue11AcceptanceTests {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func hour(offset: Int, price: Double) -> HourlyPrice {
        HourlyPrice(
            classification: .mid,
            date: referenceDate.addingTimeInterval(TimeInterval(offset * 3_600)),
            daypart: .morning,
            eurPerKWh: price
        )
    }

    static func payload(prices: [HourlyPrice]) -> DailyPricingSnapshotPayload {
        let fallbackDate = prices.first?.date ?? referenceDate
        return DailyPricingSnapshotPayload(
            dayStart: Calendar(identifier: .gregorian).startOfDay(for: referenceDate),
            fetchedAt: referenceDate,
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
