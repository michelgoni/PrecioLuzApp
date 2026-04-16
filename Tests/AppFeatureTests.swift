import Testing

@testable import PrecioLuzApp

struct AppFeatureTests {
  @Test("App tabs expose expected SF Symbols")
  func tabSymbolsAreConfigured() {
    #expect(AppTab.prices.systemImage == "eurosign.circle")
    #expect(AppTab.chart.systemImage == "chart.xyaxis.line")
    #expect(AppTab.settings.systemImage == "gearshape")
  }
}
