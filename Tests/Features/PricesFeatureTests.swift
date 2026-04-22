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
            $0.summary = payload.summary
        }
    }

    @MainActor
    @Test("PricesFeature selects hour and presents calculation placeholder")
    func hourTappedPresentsPlaceholder() async {
        let selectedHour = HourlyPrice.testValue
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.hourTapped(selectedHour)) {
            $0.calculationDurationHours = 1.0
            $0.isCalculationPlaceholderPresented = true
            $0.selectedHour = selectedHour
            $0.selectedPresetKind = .washingMachine
        }
    }

    @MainActor
    @Test("PricesFeature updates calculation duration")
    func calculationDurationHoursChanged() async {
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.calculationDurationHoursChanged(2.0)) {
            $0.calculationDurationHours = 2.0
        }
    }

    @MainActor
    @Test("PricesFeature updates selected preset")
    func calculationPresetSelected() async {
        let store = TestStore(initialState: PricesFeature.State()) {
            PricesFeature()
        }

        await store.send(.calculationPresetSelected(.airConditioner)) {
            $0.selectedPresetKind = .airConditioner
        }
    }

    @MainActor
    @Test("PricesFeature clears invalid selected hour after snapshot refresh")
    func snapshotLoadedClearsSelectionWhenHourDisappears() async {
        let initial = PricesFeature.State(selectedHour: HourlyPrice.testValue)
        let payload = DailyPricingSnapshotPayload.emptyValue
        let store = TestStore(initialState: initial) {
            PricesFeature()
        }

        await store.send(.snapshotLoaded(payload, isCached: false)) {
            $0.hourlyPrices = []
            $0.selectedHour = nil
            $0.summary = nil
        }
    }
}

private extension DailyPricingSnapshotPayload {
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
