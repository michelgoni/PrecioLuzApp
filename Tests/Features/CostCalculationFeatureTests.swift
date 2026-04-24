import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct CostCalculationFeatureTests {
    @MainActor
    @Test("CostCalculationFeature opens modal and sets selected hour")
    func hourSelectedOpensModal() async {
        let store = TestStore(initialState: CostCalculationFeature.State()) {
            CostCalculationFeature()
        }

        await store.send(.hourSelected(hourPriceTestValue)) {
            $0.durationHours = CostCalculationFeature.State.defaultDurationHours
            $0.isPresented = true
            $0.selectedHour = hourPriceTestValue
            $0.selectedPresetKind = .washingMachine
        }
    }

    @MainActor
    @Test("CostCalculationFeature dismiss closes modal")
    func dismissClosesModal() async {
        let initialState = CostCalculationFeature.State(
            durationHours: 2.0,
            isPresented: true,
            selectedHour: hourPriceTestValue,
            selectedPresetKind: .dishwasher
        )
        let store = TestStore(initialState: initialState) {
            CostCalculationFeature()
        }

        await store.send(.dismiss) {
            $0.isPresented = false
        }
    }

    @MainActor
    @Test("CostCalculationFeature updates selected preset")
    func presetSelectedUpdatesState() async {
        let store = TestStore(initialState: CostCalculationFeature.State()) {
            CostCalculationFeature()
        }

        await store.send(.presetSelected(.airConditioner)) {
            $0.selectedPresetKind = .airConditioner
        }
    }

    @MainActor
    @Test("CostCalculationFeature updates duration")
    func durationHoursChangedUpdatesState() async {
        let store = TestStore(initialState: CostCalculationFeature.State()) {
            CostCalculationFeature()
        }

        await store.send(.durationHoursChanged(2.0)) {
            $0.durationHours = 2.0
        }
    }

    @MainActor
    @Test("CostCalculationFeature clamps duration to allowed range")
    func durationHoursChangedClampsRange() async {
        let store = TestStore(initialState: CostCalculationFeature.State()) {
            CostCalculationFeature()
        }

        await store.send(.durationHoursChanged(99.0)) {
            $0.durationHours = CostCalculationFeature.State.maximumDurationHours
        }

        await store.send(.durationHoursChanged(0.0)) {
            $0.durationHours = CostCalculationFeature.State.minimumDurationHours
        }
    }

    @Test("CostCalculationFeature derives cost result from selected input")
    func calculationDerivedFromState() {
        var state = CostCalculationFeature.State()
        CostCalculationFeature.State.apply(.hourSelected(hourPriceTestValue), to: &state)
        CostCalculationFeature.State.apply(.presetSelected(.dishwasher), to: &state)
        CostCalculationFeature.State.apply(.durationHoursChanged(2.0), to: &state)

        let expected = ApplianceCostEstimator.estimate(
            durationHours: 2.0,
            preset: PricesPresetCatalog.preset(for: .dishwasher),
            selectedHour: hourPriceTestValue
        )
        #expect(state.calculation == expected)
    }

    @MainActor
    @Test("CostCalculationFeature has no result when selected hour is missing")
    func calculationIsNilWithoutSelectedHour() async {
        let state = CostCalculationFeature.State()
        #expect(state.calculation == nil)
    }
}

private let hourPriceTestValue = HourlyPrice(
    classification: .mid,
    date: Date(timeIntervalSince1970: 3_600),
    daypart: .morning,
    eurPerKWh: 0.18
)
