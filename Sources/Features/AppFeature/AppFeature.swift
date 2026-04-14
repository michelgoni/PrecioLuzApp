import SwiftUI

enum AppTab: Hashable {
  case prices
  case chart
  case settings

  var title: String {
    switch self {
    case .prices:
      String(localized: "tab.prices.title", defaultValue: "Precios")
    case .chart:
      String(localized: "tab.chart.title", defaultValue: "Gráfica")
    case .settings:
      String(localized: "tab.settings.title", defaultValue: "Ajustes")
    }
  }

  var systemImage: String {
    switch self {
    case .prices:
      "eurosign.circle"
    case .chart:
      "chart.xyaxis.line"
    case .settings:
      "gearshape"
    }
  }
}

struct AppShellView: View {
  @State private var selectedTab: AppTab = .prices

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      TabView(selection: $selectedTab) {
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
    }
  }
}
