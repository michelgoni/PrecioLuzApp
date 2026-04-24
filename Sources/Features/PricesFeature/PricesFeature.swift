import ComposableArchitecture

struct PricesFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var costCalculation = CostCalculationFeature.State()
        var hourlyPrices: [HourlyPrice] = []
        var isFromCache = false
        var summary: PriceSummary?
    }

    enum Action: Equatable {
        case costCalculation(CostCalculationFeature.Action)
        case hourTapped(HourlyPrice)
        case snapshotLoaded(DailyPricingSnapshotPayload, isCached: Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .hourTapped(hour):
                CostCalculationFeature.State.apply(.hourSelected(hour), to: &state.costCalculation)
                return .none

            case let .snapshotLoaded(payload, isCached):
                state.hourlyPrices = payload.hourlyPrices
                state.isFromCache = isCached
                state.summary = payload.summary
                CostCalculationFeature.State.apply(
                    .reconcileSelectedHour(payload.hourlyPrices),
                    to: &state.costCalculation
                )
                return .none

            case let .costCalculation(costAction):
                CostCalculationFeature.State.apply(costAction, to: &state.costCalculation)
                return .none
            }
        }
    }
}
