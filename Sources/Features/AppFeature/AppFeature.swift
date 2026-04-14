import SwiftUI

enum AppTab: Hashable {
  case prices
  case chart
  case settings

  var title: String {
    switch self {
    case .prices:
      return "Precios"
    case .chart:
      return "Gráfica"
    case .settings:
      return "Ajustes"
    }
  }

  var systemImage: String {
    switch self {
    case .prices:
      return "eurosign.circle"
    case .chart:
      return "chart.xyaxis.line"
    case .settings:
      return "gearshape"
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
