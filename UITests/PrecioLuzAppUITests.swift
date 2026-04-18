import XCTest

@MainActor
final class PrecioLuzAppUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchShowsRootStatusAndTabs() throws {
    let app = makeApp()
    app.launch()

    let tabs = app.tabBars.firstMatch
    XCTAssertTrue(tabs.waitForExistence(timeout: 5))
    XCTAssertTrue(tabs.buttons["Precios"].exists)
    XCTAssertTrue(tabs.buttons["Gráfica"].exists)
    XCTAssertTrue(tabs.buttons["Ajustes"].exists)
  }

  func testRootStatusTransitionsOutOfLoading() throws {
    let app = makeApp()
    app.launch()

    let updatedStatus = app.staticTexts["Datos actualizados"]
    let predicate = NSPredicate(format: "exists == true")
    expectation(for: predicate, evaluatedWith: updatedStatus)
    waitForExpectations(timeout: 5)
  }

  func testTabNavigationIsStable() throws {
    let app = makeApp()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

    let chartButton = tabBar.buttons["Gráfica"]
    chartButton.tap()
    XCTAssertTrue(chartButton.isSelected)

    let settingsButton = tabBar.buttons["Ajustes"]
    settingsButton.tap()
    XCTAssertTrue(settingsButton.isSelected)

    let pricesButton = tabBar.buttons["Precios"]
    pricesButton.tap()
    XCTAssertTrue(pricesButton.isSelected)
  }

  private func makeApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
    return app
  }
}
