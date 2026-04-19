import ComposableArchitecture

enum AppTab: Hashable {
    case chart
    case prices
    case settings

    var title: String {
        switch self {
        case .chart:
            String(localized: "tab.chart.title", defaultValue: "Gráfica")
        case .prices:
            String(localized: "tab.prices.title", defaultValue: "Precios")
        case .settings:
            String(localized: "tab.settings.title", defaultValue: "Ajustes")
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
        var rootStatus: RootStatus = .loading
        var selectedTab: AppTab = .prices
    }

    enum Action: Equatable {
        case onAppear
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
            case .onAppear, .retryTapped:
                state.rootStatus = .loading
                return loadSnapshotEffect()

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case let .snapshotResponse(result):
                state.rootStatus = mapRootStatus(from: result)
                return .none
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
}
