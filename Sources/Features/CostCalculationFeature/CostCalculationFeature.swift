import ComposableArchitecture

struct CostCalculationFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        static let defaultDurationHours = 1.0
        static let maximumDurationHours = 8.0
        static let minimumDurationHours = 0.5
        static let stepDurationHours = 0.5

        var durationHours: Double = State.defaultDurationHours
        var isPresented = false
        var selectedHour: HourlyPrice?
        var selectedPresetKind: AppliancePreset.Kind = .washingMachine

        var calculation: CostCalculation? {
            guard let selectedHour else {
                return nil
            }
            return ApplianceCostEstimator.estimate(
                durationHours: durationHours,
                preset: PricesPresetCatalog.preset(for: selectedPresetKind),
                selectedHour: selectedHour
            )
        }
    }

    enum Action: Equatable {
        case dismiss
        case durationHoursChanged(Double)
        case hourSelected(HourlyPrice)
        case presetSelected(AppliancePreset.Kind)
        case reconcileSelectedHour([HourlyPrice])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            State.apply(action, to: &state)
            return .none
        }
    }
}

extension CostCalculationFeature.State {
    static func apply(_ action: CostCalculationFeature.Action, to state: inout Self) {
        switch action {
        case .dismiss:
            state.isPresented = false

        case let .durationHoursChanged(durationHours):
            state.durationHours = min(
                max(durationHours, minimumDurationHours),
                maximumDurationHours
            )

        case let .hourSelected(hour):
            state.durationHours = defaultDurationHours
            state.isPresented = true
            state.selectedHour = hour
            state.selectedPresetKind = .washingMachine

        case let .presetSelected(kind):
            state.selectedPresetKind = kind

        case let .reconcileSelectedHour(hourlyPrices):
            state.selectedHour = hourlyPrices.first { $0.date == state.selectedHour?.date }
        }
    }
}
