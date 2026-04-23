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
    XCTAssertTrue(tabButton(in: tabs, names: ["Precios", "tab.prices.title"]).exists)
    XCTAssertTrue(tabButton(in: tabs, names: ["Gráfica", "tab.chart.title"]).exists)
    XCTAssertTrue(tabButton(in: tabs, names: ["Ajustes", "tab.settings.title"]).exists)
  }

  func testRootStatusTransitionsOutOfLoading() throws {
    let app = makeApp()
    app.launch()

    let updatedStatus = staticText(in: app, names: ["Datos actualizados", "app.rootStatus.content.label"])
    let predicate = NSPredicate(format: "exists == true")
    expectation(for: predicate, evaluatedWith: updatedStatus)
    waitForExpectations(timeout: 5)
  }

  func testTabNavigationIsStable() throws {
    let app = makeApp()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

    let chartButton = tabButton(in: tabBar, names: ["Gráfica", "tab.chart.title"])
    chartButton.tap()
    XCTAssertTrue(chartButton.isSelected)

    let settingsButton = tabButton(in: tabBar, names: ["Ajustes", "tab.settings.title"])
    settingsButton.tap()
    XCTAssertTrue(settingsButton.isSelected)

    let pricesButton = tabButton(in: tabBar, names: ["Precios", "tab.prices.title"])
    pricesButton.tap()
    XCTAssertTrue(pricesButton.isSelected)
  }

  private func makeApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
    return app
  }

  private func staticText(in app: XCUIApplication, names: [String]) -> XCUIElement {
    for name in names {
      let element = app.staticTexts[name]
      if element.exists {
        return element
      }
    }
    return app.staticTexts[names[0]]
  }

  private func tabButton(in tabBar: XCUIElement, names: [String]) -> XCUIElement {
    for name in names {
      let button = tabBar.buttons[name]
      if button.exists {
        return button
      }
    }
    return tabBar.buttons[names[0]]
  }
}
