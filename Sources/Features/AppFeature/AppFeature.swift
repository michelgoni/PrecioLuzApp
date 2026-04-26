import ComposableArchitecture

enum AppTab: Hashable {
    case chart
    case prices
    case settings

    var title: String {
        switch self {
        case .chart:
            String(localized: "tab.chart.title")
        case .prices:
            String(localized: "tab.prices.title")
        case .settings:
            String(localized: "tab.settings.title")
        }
    }

    var systemImage: String {
        switch self {
        case .chart:
            "chart.xyaxis.line"
        case .prices:
            "eurosign.circle"
        case .settings:
            "gearshape"
        }
    }
}

enum RootStatus: Equatable, Sendable {
    case cached
    case content
    case empty
    case error
    case loading
}

struct AppFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var chart = ChartFeature.State()
        var prices = PricesFeature.State()
        var rootStatus: RootStatus = .loading
        var selectedTab: AppTab = .prices
    }

    enum Action: Equatable {
        case chart(ChartFeature.Action)
        case onAppear
        case pricesCalculationPlaceholderDismissed
        case pricesDurationHoursChanged(Double)
        case pricesHourTapped(HourlyPrice)
        case pricesPresetSelected(AppliancePreset.Kind)
        case retryTapped
        case selectedTabChanged(AppTab)
        case snapshotResponse(DailyPricingSnapshotPipelineResult)
    }

    @Dependency(\.dateClient) var dateClient
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.pricingClient) var pricingClient

    private enum CancelID {
        case loadSnapshot
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .chart(chartAction):
                ChartFeature.State.apply(chartAction, to: &state.chart)
                return .none

            case .onAppear, .retryTapped:
                state.rootStatus = .loading
                return loadSnapshotEffect()

            case .pricesCalculationPlaceholderDismissed:
                state.prices.costCalculation.isPresented = false
                return .none

            case let .pricesDurationHoursChanged(durationHours):
                state.prices.costCalculation.durationHours = min(
                    max(durationHours, CostCalculationFeature.State.minimumDurationHours),
                    CostCalculationFeature.State.maximumDurationHours
                )
                return .none

            case let .pricesHourTapped(hour):
                state.prices.costCalculation.durationHours = CostCalculationFeature.State.defaultDurationHours
                state.prices.costCalculation.selectedPresetKind = .washingMachine
                state.prices.costCalculation.selectedHour = hour
                state.prices.costCalculation.isPresented = true
                return .none

            case let .pricesPresetSelected(kind):
                state.prices.costCalculation.selectedPresetKind = kind
                return .none

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                if tab != .prices {
                    state.prices.costCalculation.isPresented = false
                }
                return .none

            case let .snapshotResponse(result):
                state.rootStatus = mapRootStatus(from: result)
                updateFeatureStates(&state, from: result)
                return chartSyncEffect(from: result)
            }
        }
    }

    private func loadSnapshotEffect() -> Effect<Action> {
        .run { [dateClient, persistenceClient, pricingClient] send in
            let pipeline = DailyPricingSnapshotPipeline(
                dateClient: dateClient,
                persistenceClient: persistenceClient,
                pricingClient: pricingClient
            )
            let result = await pipeline.load()
            await send(.snapshotResponse(result))
        }
        .cancellable(id: CancelID.loadSnapshot, cancelInFlight: true)
    }

    private func mapRootStatus(from result: DailyPricingSnapshotPipelineResult) -> RootStatus {
        switch result {
        case .failed:
            .error
        case let .cached(payload):
            mapStatus(from: payload, whenNotEmpty: .cached)
        case let .fresh(payload):
            mapStatus(from: payload, whenNotEmpty: .content)
        }
    }

    private func mapStatus(from payload: DailyPricingSnapshotPayload, whenNotEmpty status: RootStatus) -> RootStatus {
        payload.hourlyPrices.isEmpty ? .empty : status
    }

    private func chartSyncEffect(from result: DailyPricingSnapshotPipelineResult) -> Effect<Action> {
        switch result {
        case .failed:
            return .none
        case let .cached(payload), let .fresh(payload):
            return .send(.chart(.syncHourlyPrices(payload.hourlyPrices)))
        }
    }

    private func updateFeatureStates(_ state: inout State, from result: DailyPricingSnapshotPipelineResult) {
        updatePricesState(&state.prices, from: result)
        updateChartState(&state.chart, from: result)
    }

    private func updateChartState(_ state: inout ChartFeature.State, from result: DailyPricingSnapshotPipelineResult) {
        switch result {
        case .failed:
            break
        case let .cached(payload), let .fresh(payload):
            state.hourlyPrices = payload.hourlyPrices
            if let inspectedHour = state.inspectedHour,
               !payload.hourlyPrices.contains(where: { $0.date == inspectedHour.date }) {
                state.inspectedHour = nil
            }
        }
    }

    private func updatePricesState(_ state: inout PricesFeature.State, from result: DailyPricingSnapshotPipelineResult) {
        switch result {
        case .failed:
            break
        case let .cached(payload):
            state.hourlyPrices = payload.hourlyPrices
            state.isFromCache = true
            state.costCalculation.selectedHour = payload.hourlyPrices.first {
                $0.date == state.costCalculation.selectedHour?.date
            }
            if state.costCalculation.selectedHour == nil {
                state.costCalculation.isPresented = false
            }
            state.summary = payload.summary
        case let .fresh(payload):
            state.hourlyPrices = payload.hourlyPrices
            state.isFromCache = false
            state.costCalculation.selectedHour = payload.hourlyPrices.first {
                $0.date == state.costCalculation.selectedHour?.date
            }
            if state.costCalculation.selectedHour == nil {
                state.costCalculation.isPresented = false
            }
            state.summary = payload.summary
        }
    }
}
