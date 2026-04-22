import ComposableArchitecture

struct PricesFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        static let defaultCalculationDurationHours = 1.0
        static let maximumCalculationDurationHours = 8.0
        static let minimumCalculationDurationHours = 0.5
        static let stepCalculationDurationHours = 0.5

        var calculationDurationHours: Double = State.defaultCalculationDurationHours
        var hourlyPrices: [HourlyPrice] = []
        var isCalculationPlaceholderPresented = false
        var isFromCache = false
        var selectedHour: HourlyPrice?
        var selectedPresetKind: AppliancePreset.Kind = .washingMachine
        var summary: PriceSummary?
    }

    enum Action: Equatable {
        case calculationPlaceholderDismissed
        case calculationDurationHoursChanged(Double)
        case calculationPresetSelected(AppliancePreset.Kind)
        case hourTapped(HourlyPrice)
        case snapshotLoaded(DailyPricingSnapshotPayload, isCached: Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .calculationPlaceholderDismissed:
                state.isCalculationPlaceholderPresented = false
                return .none

            case let .calculationDurationHoursChanged(durationHours):
                state.calculationDurationHours = max(State.minimumCalculationDurationHours, durationHours)
                return .none

            case let .calculationPresetSelected(kind):
                state.selectedPresetKind = kind
                return .none

            case let .hourTapped(hour):
                state.calculationDurationHours = State.defaultCalculationDurationHours
                state.selectedPresetKind = .washingMachine
                state.selectedHour = hour
                state.isCalculationPlaceholderPresented = true
                return .none

            case let .snapshotLoaded(payload, isCached):
                state.hourlyPrices = payload.hourlyPrices
                state.isFromCache = isCached
                state.selectedHour = payload.hourlyPrices.first { $0.date == state.selectedHour?.date }
                state.summary = payload.summary
                return .none
            }
        }
    }
}
