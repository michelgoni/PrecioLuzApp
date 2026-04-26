import ComposableArchitecture
import SwiftUI

struct AppShellView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        ZStack {
            backgroundView
            tabView
        }
        .safeAreaInset(edge: .top) {
            statusBannerOverlay
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        .sheet(isPresented: calculationSheetPresentedBinding) {
            PricesCalculationSheetView(
                durationHours: store.prices.costCalculation.durationHours,
                durationHoursBinding: calculationDurationBinding,
                estimatedCostDescription: estimatedCostDescription,
                onCloseTapped: { store.send(.pricesCalculationPlaceholderDismissed) },
                presetBinding: selectedPresetBinding,
                selectedHour: store.prices.costCalculation.selectedHour,
                presets: PricesPresetCatalog.all
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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
        .accessibilityIdentifier("appRootStatusBanner")
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { store.selectedTab },
            set: { store.send(.selectedTabChanged($0)) }
        )
    }

    private var calculationDurationBinding: Binding<Double> {
        Binding(
            get: { store.prices.costCalculation.durationHours },
            set: { store.send(.pricesDurationHoursChanged($0)) }
        )
    }

    private var calculationSheetPresentedBinding: Binding<Bool> {
        Binding(
            get: {
                store.selectedTab == .prices && store.prices.costCalculation.isPresented
            },
            set: { isPresented in
                if !isPresented {
                    store.send(.pricesCalculationPlaceholderDismissed)
                }
            }
        )
    }

    private var estimatedCostDescription: String {
        guard let estimatedCostEUR = store.prices.costCalculation.calculation?.estimatedCostEUR else {
            return String(localized: "prices.calculation.result.empty")
        }
        return PricesViewFormatting.price(estimatedCostEUR)
    }

    private var selectedPresetBinding: Binding<AppliancePreset.Kind> {
        Binding(
            get: { store.prices.costCalculation.selectedPresetKind },
            set: { store.send(.pricesPresetSelected($0)) }
        )
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
            PricesView(
                onHourTapped: { store.send(.pricesHourTapped($0)) },
                state: store.prices
            )
                .tabItem {
                    Label(AppTab.prices.title, systemImage: AppTab.prices.systemImage)
                        .accessibilityIdentifier("tabPrices")
                }
                .tag(AppTab.prices)

            ChartView(
                store: store
            )
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
