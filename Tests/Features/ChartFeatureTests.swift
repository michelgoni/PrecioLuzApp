import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

@MainActor
struct ChartFeatureTests {
    @Test("ChartFeature filters hourly prices by selected daypart")
    func selectedDaypartChangedFiltersPrices() async {
        let morningPrice = makeHourlyPrice(hour: 8, daypart: .morning, eurPerKWh: 0.12)
        let afternoonPrice = makeHourlyPrice(hour: 14, daypart: .afternoon, eurPerKWh: 0.20)
        let store = TestStore(initialState: ChartFeature.State()) {
            ChartFeature()
        }

        await store.send(.syncHourlyPrices([morningPrice, afternoonPrice])) {
            $0.hourlyPrices = [morningPrice, afternoonPrice]
        }
        await store.send(.selectedDaypartChanged(.afternoon)) {
            $0.selectedDaypart = .afternoon
        }
        #expect(store.state.filteredPrices == [afternoonPrice])
    }

    @Test("ChartFeature supports selecting and clearing inspected hour")
    func inspectedHourChangedUpdatesState() async {
        let inspected = makeHourlyPrice(hour: 9, daypart: .morning, eurPerKWh: 0.15)
        let store = TestStore(initialState: ChartFeature.State()) {
            ChartFeature()
        }

        await store.send(.inspectedHourChanged(inspected)) {
            $0.inspectedHour = inspected
        }
        await store.send(.inspectedHourChanged(nil)) {
            $0.inspectedHour = nil
        }
    }

    @Test("ChartFeature reconciles inspected hour when daypart changes")
    func selectedDaypartChangedClearsInvalidInspection() async {
        let morningPrice = makeHourlyPrice(hour: 7, daypart: .morning, eurPerKWh: 0.11)
        let afternoonPrice = makeHourlyPrice(hour: 16, daypart: .afternoon, eurPerKWh: 0.19)
        let store = TestStore(initialState: ChartFeature.State()) {
            ChartFeature()
        }

        await store.send(.syncHourlyPrices([morningPrice, afternoonPrice])) {
            $0.hourlyPrices = [morningPrice, afternoonPrice]
        }
        await store.send(.inspectedHourChanged(morningPrice)) {
            $0.inspectedHour = morningPrice
        }
        await store.send(.selectedDaypartChanged(.afternoon)) {
            $0.inspectedHour = nil
            $0.selectedDaypart = .afternoon
        }
    }

    @Test("ChartFeature reconciles inspected hour when prices refresh")
    func syncHourlyPricesClearsStaleInspection() async {
        let morningPrice = makeHourlyPrice(hour: 6, daypart: .morning, eurPerKWh: 0.10)
        let replacementPrice = makeHourlyPrice(hour: 10, daypart: .morning, eurPerKWh: 0.17)
        let store = TestStore(initialState: ChartFeature.State()) {
            ChartFeature()
        }

        await store.send(.syncHourlyPrices([morningPrice])) {
            $0.hourlyPrices = [morningPrice]
        }
        await store.send(.inspectedHourChanged(morningPrice)) {
            $0.inspectedHour = morningPrice
        }
        await store.send(.syncHourlyPrices([replacementPrice])) {
            $0.hourlyPrices = [replacementPrice]
            $0.inspectedHour = nil
        }
    }
}

private func makeHourlyPrice(hour: Int, daypart: Daypart, eurPerKWh: Double) -> HourlyPrice {
    let date = Date(timeIntervalSince1970: TimeInterval(hour * 3_600))
    return HourlyPrice(
        classification: .mid,
        date: date,
        daypart: daypart,
        eurPerKWh: eurPerKWh
    )
}
