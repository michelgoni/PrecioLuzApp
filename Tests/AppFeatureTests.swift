import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct AppFeatureTests {
  @MainActor
  @Test("AppFeature sets selected tab")
  func selectedTabChanged() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.selectedTabChanged(.settings)) {
      $0.selectedTab = .settings
    }
  }

  @MainActor
  @Test("AppFeature sets loading on onAppear")
  func onAppearSetsLoading() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.dateClient = .fixed(now: .mockNow, timeZone: .zeroGMT)
    }
    store.exhaustivity = .off

    await store.send(.onAppear) {
      $0.rootStatus = .loading
    }
  }

  @MainActor
  @Test("AppFeature maps fresh snapshot to content")
  func freshMapsToContent() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.fresh(.mockPayload(withPrices: true)))) {
      $0.rootStatus = .content
    }
  }

  @MainActor
  @Test("AppFeature maps cached snapshot to cached")
  func cachedMapsToCached() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.cached(.mockPayload(withPrices: true)))) {
      $0.rootStatus = .cached
    }
  }

  @MainActor
  @Test("AppFeature maps failed result to error")
  func failedMapsToError() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.failed)) {
      $0.rootStatus = .error
    }
  }

  @MainActor
  @Test("AppFeature maps empty fresh snapshot to empty")
  func emptyFreshMapsToEmpty() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.fresh(.mockPayload(withPrices: false)))) {
      $0.rootStatus = .empty
    }
  }

  @Test("App tabs expose expected SF Symbols")
  func tabSymbolsAreConfigured() {
    #expect(AppTab.chart.systemImage == "chart.xyaxis.line")
    #expect(AppTab.prices.systemImage == "eurosign.circle")
    #expect(AppTab.settings.systemImage == "gearshape")
  }
}

private extension Date {
  static let mockNow = Date(timeIntervalSince1970: 1_700_000_000)
}

private extension DateClient {
  static func fixed(now: Date, timeZone: TimeZone) -> Self {
    DateClient(
      now: { now },
      calendar: { Calendar(identifier: .gregorian) },
      timeZone: { timeZone }
    )
  }
}

private extension DailyPricingSnapshotPayload {
  static func mockPayload(withPrices: Bool) -> Self {
    let prices = withPrices ? [HourlyPrice.mockValue] : []
    return .init(
      dayStart: .mockNow,
      fetchedAt: .mockNow,
      hourlyPrices: prices,
      summary: nil
    )
  }
}

private extension HourlyPrice {
  static let mockValue = HourlyPrice(
    classification: .cheap,
    date: .mockNow,
    daypart: .morning,
    eurPerKWh: 0.15
  )
}

private extension TimeZone {
  static let zeroGMT = TimeZone(secondsFromGMT: 0) ?? .current
}
