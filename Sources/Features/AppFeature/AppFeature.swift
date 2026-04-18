import ComposableArchitecture
import SwiftUI

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
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.rootStatus = .loading
                return loadSnapshotEffect()
                
            case .retryTapped:
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
    }
    
    private func mapRootStatus(from result: DailyPricingSnapshotPipelineResult) -> RootStatus {
        switch result {
        case let .cached(payload):
            payload.hourlyPrices.isEmpty ? .empty : .cached
        case .failed:
                .error
        case let .fresh(payload):
            payload.hourlyPrices.isEmpty ? .empty : .content
        }
    }
}

struct AppShellView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      TabView(
        selection: Binding(
          get: { store.selectedTab },
          set: { store.send(.selectedTabChanged($0)) }
        )
      ) {
        PricesView()
          .tabItem {
            Label(AppTab.prices.title, systemImage: AppTab.prices.systemImage)
          }
          .tag(AppTab.prices)

        ChartView()
          .tabItem {
            Label(AppTab.chart.title, systemImage: AppTab.chart.systemImage)
          }
          .tag(AppTab.chart)

        SettingsView()
          .tabItem {
            Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
          }
          .tag(AppTab.settings)
      }
      .accessibilityIdentifier("appTabView")

      RootStatusBanner(
        onRetry: { store.send(.retryTapped) },
        status: store.rootStatus
      )
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .accessibilityIdentifier("appRootStatusBanner")
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}

#Preview("App shell - loading") {
    AppShellView(
        store: Store(
            initialState: AppFeature.State(
                rootStatus: .loading,
                selectedTab: .prices
            )
        ) {
            AppFeature()
        }
    )
}

#Preview("App shell - error") {
    AppShellView(
        store: Store(
            initialState: AppFeature.State(
                rootStatus: .error,
                selectedTab: .prices
            )
        ) {
            AppFeature()
        }
    )
}

#Preview("App shell - chart") {
    AppShellView(
        store: Store(
            initialState: AppFeature.State(
                rootStatus: .content,
                selectedTab: .chart
            )
        ) {
            AppFeature()
        }
    )
}

#Preview("App shell - settings") {
    AppShellView(
        store: Store(
            initialState: AppFeature.State(
                rootStatus: .cached,
                selectedTab: .settings
            )
        ) {
            AppFeature()
        }
    )
}
