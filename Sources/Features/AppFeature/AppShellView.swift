import ComposableArchitecture
import SwiftUI

struct AppShellView: View {
    @Environment(\.scenePhase) private var scenePhase
    let store: StoreOf<AppFeature>

    var body: some View {
        ZStack {
            backgroundView
            rootContent
        }
        .safeAreaInset(edge: .top) {
            if store.onboardingStatus == .completed && store.rootStatus != .content {
                statusBannerOverlay
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
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
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            store.send(.appDidBecomeActive)
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

    @ViewBuilder
    private var rootContent: some View {
        switch store.onboardingStatus {
        case .completed:
            tabView
                .transition(.opacity)
        case .required:
            OnboardingView(
                store: store.scope(
                    state: \.onboarding,
                    action: \.onboarding
                )
            )
            .transition(.opacity)
        case .unknown:
            ProgressView()
                .tint(.secondary)
                .accessibilityIdentifier("appBootstrapLoadingView")
        }
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                PricesView(
                    onHourTapped: { store.send(.pricesHourTapped($0)) },
                    state: store.prices
                )
                .navigationTitle(String(localized: "tab.prices.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
                .tabItem {
                    Label(AppTab.prices.title, systemImage: AppTab.prices.systemImage)
                        .accessibilityIdentifier("tabPrices")
                }
                .tag(AppTab.prices)

            NavigationStack {
                ChartView(
                    store: store.scope(
                        state: \.chart,
                        action: \.chart
                    )
                )
                .navigationTitle(String(localized: "tab.chart.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
                .tabItem {
                    Label(AppTab.chart.title, systemImage: AppTab.chart.systemImage)
                        .accessibilityIdentifier("tabChart")
                }
                .tag(AppTab.chart)

            SettingsView(
                store: store.scope(
                    state: \.settings,
                    action: \.settings
                )
            )
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
                        .accessibilityIdentifier("tabSettings")
                }
                .tag(AppTab.settings)
        }
        .accessibilityIdentifier("appTabView")
    }
}

#Preview("App shell - prices") {
    AppShellView(
        store: previewStore(
            initialState: AppFeature.State(
                rootStatus: .loading,
                selectedTab: .prices
            )
        )
    )
}

#Preview("App shell - error") {
    AppShellView(
        store: previewStore(
            initialState: AppFeature.State(
                rootStatus: .error,
                selectedTab: .prices
            )
        )
    )
}

#Preview("App shell - chart") {
    AppShellView(
        store: previewStore(
            initialState: AppFeature.State(
                rootStatus: .content,
                selectedTab: .chart
            )
        )
    )
}

#Preview("App shell - settings") {
    AppShellView(
        store: previewStore(
            initialState: AppFeature.State(
                rootStatus: .cached,
                selectedTab: .settings
            )
        )
    )
}


@MainActor
private func previewStore(initialState: AppFeature.State) -> StoreOf<AppFeature> {
    Store(initialState: initialState) {
        AppFeature()
    } withDependencies: {
        $0.dateClient = DateClient(
            now: { Date(timeIntervalSince1970: 1_700_000_000) },
            calendar: { Calendar(identifier: .gregorian) },
            timeZone: { TimeZone(identifier: "Europe/Madrid") ?? .current }
        )
        $0.notificationClient = .testValue
        $0.persistenceClient = .testValue
        $0.pricingClient = .testValue
    }
}

private func makePricesHeadersPreviewState() -> PricesFeature.State {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .current
    let todayStart = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
    let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

    let prices = [
        HourlyPrice(
            classification: .mid,
            date: calendar.date(byAdding: .hour, value: 20, to: todayStart) ?? todayStart,
            daypart: .night,
            eurPerKWh: 0.162
        ),
        HourlyPrice(
            classification: .expensive,
            date: calendar.date(byAdding: .hour, value: 21, to: todayStart) ?? todayStart,
            daypart: .night,
            eurPerKWh: 0.201
        ),
        HourlyPrice(
            classification: .cheap,
            date: calendar.date(byAdding: .hour, value: 0, to: tomorrowStart) ?? tomorrowStart,
            daypart: .overnight,
            eurPerKWh: 0.118
        ),
        HourlyPrice(
            classification: .mid,
            date: calendar.date(byAdding: .hour, value: 1, to: tomorrowStart) ?? tomorrowStart,
            daypart: .overnight,
            eurPerKWh: 0.133
        ),
    ]

    return PricesFeature.State(
        costCalculation: CostCalculationFeature.State(),
        hourlyListPresentationMode: .withDateHeaders,
        hourlyPrices: prices,
        isFromCache: false,
        isLoading: false,
        summary: PriceSummary(
            average: 0.181,
            current: prices[0],
            maximum: 0.201,
            maximumHour: prices[1].date,
            minimum: 0.162,
            minimumHour: prices[0].date
        ),
        visibleHourlyPrices: prices
    )
}
