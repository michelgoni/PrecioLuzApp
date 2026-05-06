import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct PricesFeatureTests {
    @MainActor
    @Test("PricesFeature stores snapshot payload and cache origin")
    func snapshotLoadedSetsState() async {
        let payload = DailyPricingSnapshotPayload.testValue
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.snapshotLoaded(payload, isCached: true)) {
            $0.hourlyPrices = payload.hourlyPrices
            $0.isFromCache = true
            $0.isLoading = false
            $0.summary = payload.summary
            $0.visibleHourlyPrices = payload.hourlyPrices
        }
    }

    @MainActor
    @Test("PricesFeature selects hour and presents calculation placeholder")
    func hourTappedPresentsPlaceholder() async {
        let selectedHour = HourlyPrice.testValue
        var initial = PricesFeature.State()
        initial.hourlyPrices = [selectedHour]
        initial.visibleHourlyPrices = [selectedHour]
        let store = TestStore(initialState: initial) {
            PricesFeature()
        }

        await store.send(.hourTapped(selectedHour)) {
            $0.costCalculation.durationHours = 1.0
            $0.costCalculation.isPresented = true
            $0.costCalculation.selectedHour = selectedHour
            $0.costCalculation.selectedPresetKind = .washingMachine
        }
    }

    @MainActor
    @Test("PricesFeature updates calculation duration")
    func calculationDurationHoursChanged() async {
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.costCalculation(.durationHoursChanged(2.0))) {
            $0.costCalculation.durationHours = 2.0
        }
    }

    @MainActor
    @Test("PricesFeature updates selected preset")
    func calculationPresetSelected() async {
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.costCalculation(.presetSelected(.airConditioner))) {
            $0.costCalculation.selectedPresetKind = .airConditioner
        }
    }

    @MainActor
    @Test("PricesFeature clears invalid selected hour after snapshot refresh")
    func snapshotLoadedClearsSelectionWhenHourDisappears() async {
        var initial = PricesFeature.State()
        initial.costCalculation.isPresented = true
        initial.costCalculation.selectedHour = HourlyPrice.testValue
        let payload = DailyPricingSnapshotPayload.emptyValue
        let store = TestStore(initialState: initial) {
            PricesFeature()
        }

        await store.send(.snapshotLoaded(payload, isCached: false)) {
            $0.hourlyPrices = []
            $0.costCalculation.isPresented = false
            $0.costCalculation.selectedHour = nil
            $0.isLoading = false
            $0.summary = nil
            $0.visibleHourlyPrices = []
        }
    }

    @MainActor
    @Test("PricesFeature filters hourly prices from the current local hour")
    func snapshotLoadedFiltersVisibleHoursFromCurrentHour() async {
        let payload = DailyPricingSnapshotPayload.dayValue
        let now = payload.dayStart.addingTimeInterval((10 * 3_600) + 1_800)
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        } withDependencies: {
            $0.dateClient.now = { now }
            $0.dateClient.timeZone = { TimeZone(secondsFromGMT: .zero) ?? .current }
        }

        await store.send(.snapshotLoaded(payload, isCached: false)) {
            $0.hourlyPrices = payload.hourlyPrices
            $0.isLoading = false
            $0.summary = payload.summary
            $0.visibleHourlyPrices = Array(payload.hourlyPrices[10...23])
        }
    }

    @MainActor
    @Test("PricesFeature ignores taps for hidden past hours")
    func hourTappedIgnoresPastHour() async {
        let payload = DailyPricingSnapshotPayload.dayValue
        var initial = PricesFeature.State()
        initial.hourlyPrices = payload.hourlyPrices
        initial.visibleHourlyPrices = Array(payload.hourlyPrices[10...23])
        let store = TestStore(initialState: initial) {
            PricesFeature()
        }

        await store.send(.hourTapped(payload.hourlyPrices[9]))
    }

    @MainActor
    @Test("PricesFeature clears selection when refreshed visible hours no longer include it")
    func snapshotLoadedClearsSelectionWhenSelectedHourExpires() async {
        let payload = DailyPricingSnapshotPayload.dayValue
        let selectedHour = payload.hourlyPrices[10]
        var initial = PricesFeature.State()
        initial.costCalculation.isPresented = true
        initial.costCalculation.selectedHour = selectedHour
        initial.hourlyPrices = payload.hourlyPrices
        initial.visibleHourlyPrices = Array(payload.hourlyPrices[10...23])
        let now = payload.dayStart.addingTimeInterval(11 * 3_600)
        let store = TestStore(initialState: initial) {
            PricesFeature()
        } withDependencies: {
            $0.dateClient.now = { now }
            $0.dateClient.timeZone = { TimeZone(secondsFromGMT: .zero) ?? .current }
        }

        await store.send(.snapshotLoaded(payload, isCached: false)) {
            $0.costCalculation.isPresented = false
            $0.costCalculation.selectedHour = nil
            $0.hourlyPrices = payload.hourlyPrices
            $0.isLoading = false
            $0.summary = payload.summary
            $0.visibleHourlyPrices = Array(payload.hourlyPrices[11...23])
        }
    }

    @MainActor
    @Test("PricesFeature keeps full cached data when no visible hours remain")
    func snapshotLoadedKeepsCachedDataWhenVisibleHoursAreEmpty() async {
        let payload = DailyPricingSnapshotPayload.dayValue
        let now = payload.dayStart.addingTimeInterval(24 * 3_600)
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        } withDependencies: {
            $0.dateClient.now = { now }
            $0.dateClient.timeZone = { TimeZone(secondsFromGMT: .zero) ?? .current }
        }

        await store.send(.snapshotLoaded(payload, isCached: true)) {
            $0.hourlyPrices = payload.hourlyPrices
            $0.isFromCache = true
            $0.isLoading = false
            $0.summary = payload.summary
            $0.visibleHourlyPrices = []
        }
    }

}

private extension DailyPricingSnapshotPayload {
    static var dayValue: Self {
        let dayStart = Date(timeIntervalSince1970: 1_700_000_000)
        let prices = (0..<24).map { hour in
            HourlyPrice(
                classification: .mid,
                date: dayStart.addingTimeInterval(TimeInterval(hour * 3_600)),
                daypart: .morning,
                eurPerKWh: 0.10 + (Double(hour) * 0.01)
            )
        }
        return Self(
            dayStart: dayStart,
            fetchedAt: dayStart.addingTimeInterval(10 * 3_600),
            hourlyPrices: prices,
            summary: PriceSummary.from(prices)
        )
    }

    static var emptyValue: Self {
        Self(
            dayStart: Date(timeIntervalSince1970: 0),
            fetchedAt: Date(timeIntervalSince1970: 0),
            hourlyPrices: [],
            summary: nil
        )
    }

    static var testValue: Self {
        Self(
            dayStart: Date(timeIntervalSince1970: 0),
            fetchedAt: Date(timeIntervalSince1970: 0),
            hourlyPrices: [HourlyPrice.testValue],
            summary: PriceSummary.from([HourlyPrice.testValue])
        )
    }
}

private extension HourlyPrice {
    static var testValue: Self {
        Self(
            classification: .mid,
            date: Date(timeIntervalSince1970: 3_600),
            daypart: .morning,
            eurPerKWh: 0.18
        )
    }
}
