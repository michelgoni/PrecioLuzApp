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

  func testRootStatusBannerHidesWhenContentIsLoaded() throws {
    let app = makeApp()
    app.launch()

    let banner = app.otherElements["appRootStatusBanner"]
    XCTAssertFalse(banner.waitForExistence(timeout: 5))
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

  func testHourlyRowTapPresentsAndDismissesCalculationModal() throws {
    let app = makeApp()
    app.launch()

    let hourlyRow = app.buttons["pricesHourlyRow0"]
    if !hourlyRow.waitForExistence(timeout: 5) {
      let emptyState = app.staticTexts["pricesHourlyEmpty"]
      if emptyState.waitForExistence(timeout: 2) {
        throw XCTSkip("No hourly prices available in current live dataset.")
      }
      XCTFail("Expected first hourly row or hourly empty state.")
      return
    }
    hourlyRow.tap()

    let modalTitle = app.staticTexts["pricesCalculationPlaceholderTitle"]
    XCTAssertTrue(modalTitle.waitForExistence(timeout: 3))

    let closeButton = app.buttons["pricesCalculationPlaceholderCloseButton"]
    XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
    closeButton.tap()

    XCTAssertFalse(modalTitle.waitForExistence(timeout: 2))
  }

  func testChartTabDoesNotPresentCalculationModal() throws {
    let app = makeApp()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

    let chartButton = tabButton(in: tabBar, names: ["Gráfica", "tab.chart.title"])
    chartButton.tap()
    XCTAssertTrue(chartButton.isSelected)

    let modalTitle = app.staticTexts["pricesCalculationPlaceholderTitle"]
    XCTAssertFalse(modalTitle.waitForExistence(timeout: 2))
  }

  func testChartDaypartSelectionAndInteractionIsStable() throws {
    let app = makeApp()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

    let chartButton = tabButton(in: tabBar, names: ["Gráfica", "tab.chart.title"])
    chartButton.tap()
    XCTAssertTrue(chartButton.isSelected)

    let daypartButton = button(
      in: app,
      names: ["Tarde", "chart.daypart.afternoon"]
    )
    XCTAssertTrue(daypartButton.waitForExistence(timeout: 5))
    daypartButton.tap()
    XCTAssertTrue(daypartButton.isSelected)

    let chartSeries = app.otherElements.matching(identifier: "chartDailySeries").firstMatch
    if !chartSeries.waitForExistence(timeout: 5) {
      let emptyChartState = app.staticTexts["chartEmptyState"]
      if emptyChartState.waitForExistence(timeout: 2) {
        throw XCTSkip("No chart series available in current live dataset.")
      }
      XCTFail("Expected chart series or chart empty state.")
      return
    }

    let start = chartSeries.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.50))
    let end = chartSeries.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.50))
    start.press(forDuration: 0.1, thenDragTo: end)

    XCTAssertTrue(chartSeries.exists)
  }

  func testSettingsTabSmokeInteractionsAreStable() throws {
    let app = makeApp()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

    let settingsButton = tabButton(in: tabBar, names: ["Ajustes", "tab.settings.title"])
    settingsButton.tap()
    XCTAssertTrue(settingsButton.isSelected)

    let settingsScreen = app.descendants(matching: .any)["settingsScreen"]
    XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))

    let notificationsToggle = app.switches["settingsNotificationsEnabledToggle"]
    XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5))
    notificationsToggle.tap()

    let minimumToggle = app.switches["settingsNotifyDailyMinimumToggle"]
    XCTAssertTrue(minimumToggle.waitForExistence(timeout: 5))
    minimumToggle.tap()

    let thresholdToggle = app.switches["settingsCustomThresholdEnabledToggle"]
    XCTAssertTrue(thresholdToggle.waitForExistence(timeout: 5))
    thresholdToggle.tap()

    let thresholdStepper = app.steppers["settingsThresholdStepper"]
    XCTAssertTrue(thresholdStepper.waitForExistence(timeout: 5))
    XCTAssertTrue(thresholdStepper.isHittable)
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

  private func button(in app: XCUIApplication, names: [String]) -> XCUIElement {
    for name in names {
      let element = app.buttons[name]
      if element.exists {
        return element
      }
    }
    return app.buttons[names[0]]
  }
}
