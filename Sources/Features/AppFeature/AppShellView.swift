import ComposableArchitecture
import SwiftUI

struct AppShellView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        ZStack {
            backgroundView
            tabView
            statusBannerOverlay
        }
        .task {
            store.send(.onAppear)
        }
    }

    private var backgroundView: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
    }

    private var statusBannerOverlay: some View {
        RootStatusBanner(
            onRetry: { store.send(.retryTapped) },
            status: store.rootStatus
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityIdentifier("appRootStatusBanner")
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { store.selectedTab },
            set: { store.send(.selectedTabChanged($0)) }
        )
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
            PricesView(state: store.prices)
                .tabItem {
                    Label(AppTab.prices.title, systemImage: AppTab.prices.systemImage)
                        .accessibilityIdentifier("tabPrices")
                }
                .tag(AppTab.prices)

            ChartView()
                .tabItem {
                    Label(AppTab.chart.title, systemImage: AppTab.chart.systemImage)
                        .accessibilityIdentifier("tabChart")
                }
                .tag(AppTab.chart)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
                        .accessibilityIdentifier("tabSettings")
                }
                .tag(AppTab.settings)
        }
        .accessibilityIdentifier("appTabView")
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
