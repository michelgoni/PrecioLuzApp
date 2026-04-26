import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct Issue9AcceptanceTests {
    @MainActor
    @Test("Acceptance #9: chart daypart filtering and inspection follow user flow")
    func chartFilteringAndInspectionFlow() async {
        let payload = Self.makePayload(
            prices: [
                Self.makeHourlyPrice(hourOffset: 1, daypart: .overnight, price: 0.11),
                Self.makeHourlyPrice(hourOffset: 8, daypart: .morning, price: 0.16),
                Self.makeHourlyPrice(hourOffset: 14, daypart: .afternoon, price: 0.22),
                Self.makeHourlyPrice(hourOffset: 21, daypart: .night, price: 0.18),
            ]
        )
        let afternoonHour = payload.hourlyPrices[2]
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(payload))) {
            $0.prices.hourlyPrices = payload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.summary = payload.summary
            $0.rootStatus = .content
        }
        await store.receive(.chart(.syncHourlyPrices(payload.hourlyPrices))) {
            $0.chart.hourlyPrices = payload.hourlyPrices
        }

        await store.send(.chart(.selectedDaypartChanged(.afternoon))) {
            $0.chart.selectedDaypart = .afternoon
        }
        #expect(store.state.chart.filteredPrices == [afternoonHour])

        await store.send(.chart(.inspectedHourChanged(afternoonHour))) {
            $0.chart.inspectedHour = afternoonHour
        }
    }

    @MainActor
    @Test("Acceptance #9: chart clears stale inspection after refresh")
    func chartClearsStaleInspectionAfterRefresh() async {
        let firstPayload = Self.makePayload(
            prices: [Self.makeHourlyPrice(hourOffset: 14, daypart: .afternoon, price: 0.19)]
        )
        let refreshedPayload = Self.makePayload(
            prices: [Self.makeHourlyPrice(hourOffset: 15, daypart: .afternoon, price: 0.23)]
        )
        let inspectedHour = firstPayload.hourlyPrices[0]
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.snapshotResponse(.fresh(firstPayload))) {
            $0.prices.hourlyPrices = firstPayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.summary = firstPayload.summary
            $0.rootStatus = .content
        }
        await store.receive(.chart(.syncHourlyPrices(firstPayload.hourlyPrices))) {
            $0.chart.hourlyPrices = firstPayload.hourlyPrices
        }
        await store.send(.chart(.selectedDaypartChanged(.afternoon))) {
            $0.chart.selectedDaypart = .afternoon
        }
        await store.send(.chart(.inspectedHourChanged(inspectedHour))) {
            $0.chart.inspectedHour = inspectedHour
        }

        await store.send(.snapshotResponse(.fresh(refreshedPayload))) {
            $0.prices.hourlyPrices = refreshedPayload.hourlyPrices
            $0.prices.isFromCache = false
            $0.prices.summary = refreshedPayload.summary
            $0.rootStatus = .content
        }
        await store.receive(.chart(.syncHourlyPrices(refreshedPayload.hourlyPrices))) {
            $0.chart.hourlyPrices = refreshedPayload.hourlyPrices
            $0.chart.inspectedHour = nil
        }
    }
}

private extension Issue9AcceptanceTests {
    static func makeHourlyPrice(hourOffset: Int, daypart: Daypart, price: Double) -> HourlyPrice {
        HourlyPrice(
            classification: .mid,
            date: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(hourOffset * 3_600)),
            daypart: daypart,
            eurPerKWh: price
        )
    }

    static func makePayload(prices: [HourlyPrice]) -> DailyPricingSnapshotPayload {
        let fallbackDate = prices.first?.date ?? Date(timeIntervalSince1970: 1_700_000_000)
        return DailyPricingSnapshotPayload(
            dayStart: Date(timeIntervalSince1970: 1_699_996_400),
            fetchedAt: Date(timeIntervalSince1970: 1_700_010_800),
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
