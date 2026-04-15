import XCTest

@testable import PrecioLuzApp

final class AppFeatureTests: XCTestCase {
  func testTabSymbolsAreConfigured() {
    XCTAssertEqual(AppTab.prices.systemImage, "eurosign.circle")
    XCTAssertEqual(AppTab.chart.systemImage, "chart.xyaxis.line")
    XCTAssertEqual(AppTab.settings.systemImage, "gearshape")
  }
}
