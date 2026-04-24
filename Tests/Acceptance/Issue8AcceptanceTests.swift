import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct Issue8AcceptanceTests {
  @MainActor
  @Test("Acceptance #8: cost calculation flow updates result from selected hour, preset and duration")
  func costCalculationFlowUpdatesResult() async throws {
    let payload = Self.makePayload(
      prices: [
        Self.makeHourlyPrice(hourOffset: 0, price: 0.10),
        Self.makeHourlyPrice(hourOffset: 1, price: 0.20),
        Self.makeHourlyPrice(hourOffset: 2, price: 0.30),
      ]
    )
    let selectedHour = payload.hourlyPrices[1]
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.fresh(payload))) {
      $0.prices.hourlyPrices = payload.hourlyPrices
      $0.prices.isFromCache = false
      $0.prices.summary = payload.summary
      $0.rootStatus = .content
    }

    await store.send(.pricesHourTapped(selectedHour)) {
      $0.prices.costCalculation.durationHours = CostCalculationFeature.State.defaultDurationHours
      $0.prices.costCalculation.isPresented = true
      $0.prices.costCalculation.selectedHour = selectedHour
      $0.prices.costCalculation.selectedPresetKind = .washingMachine
    }

    await store.send(.pricesPresetSelected(.dishwasher)) {
      $0.prices.costCalculation.selectedPresetKind = .dishwasher
    }

    await store.send(.pricesDurationHoursChanged(2.0)) {
      $0.prices.costCalculation.durationHours = 2.0
    }

    let calculation = try #require(store.state.prices.costCalculation.calculation)
    let preset = PricesPresetCatalog.preset(for: .dishwasher)
    let expected = selectedHour.eurPerKWh * preset.powerKW * 2.0
    let epsilon = 0.000_001

    #expect(abs(calculation.estimatedCostEUR - expected) < epsilon)
  }

  @MainActor
  @Test("Acceptance #8: stale selected hour is cleared and modal is dismissed after refresh")
  func staleSelectedHourIsClearedAndModalDismissed() async {
    let firstPayload = Self.makePayload(
      prices: [
        Self.makeHourlyPrice(hourOffset: 0, price: 0.10),
        Self.makeHourlyPrice(hourOffset: 1, price: 0.20),
      ]
    )
    let selectedHour = firstPayload.hourlyPrices[1]
    let refreshedPayload = Self.makePayload(
      prices: [
        Self.makeHourlyPrice(hourOffset: 3, price: 0.15),
        Self.makeHourlyPrice(hourOffset: 4, price: 0.25),
      ]
    )
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.fresh(firstPayload))) {
      $0.prices.hourlyPrices = firstPayload.hourlyPrices
      $0.prices.isFromCache = false
      $0.prices.summary = firstPayload.summary
      $0.rootStatus = .content
    }

    await store.send(.pricesHourTapped(selectedHour)) {
      $0.prices.costCalculation.durationHours = CostCalculationFeature.State.defaultDurationHours
      $0.prices.costCalculation.isPresented = true
      $0.prices.costCalculation.selectedHour = selectedHour
      $0.prices.costCalculation.selectedPresetKind = .washingMachine
    }

    await store.send(.snapshotResponse(.fresh(refreshedPayload))) {
      $0.prices.hourlyPrices = refreshedPayload.hourlyPrices
      $0.prices.isFromCache = false
      $0.prices.costCalculation.isPresented = false
      $0.prices.costCalculation.selectedHour = nil
      $0.prices.summary = refreshedPayload.summary
      $0.rootStatus = .content
    }
  }
}

private extension Issue8AcceptanceTests {
  static func makeHourlyPrice(hourOffset: Int, price: Double) -> HourlyPrice {
    HourlyPrice(
      classification: .mid,
      date: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(hourOffset * 3_600)),
      daypart: .morning,
      eurPerKWh: price
    )
  }

  static func makePayload(prices: [HourlyPrice]) -> DailyPricingSnapshotPayload {
    let fallbackDate = prices.first?.date ?? Date(timeIntervalSince1970: 1_700_000_000)
    return DailyPricingSnapshotPayload(
      dayStart: Date(timeIntervalSince1970: 1_699_996_400),
      fetchedAt: Date(timeIntervalSince1970: 1_700_010_800),
      hourlyPrices: prices,
      summary: PriceSummary(
        average: prices.reduce(0) { $0 + $1.eurPerKWh } / Double(prices.count),
        current: prices.first,
        maximum: prices.map(\.eurPerKWh).max() ?? 0,
        maximumHour: prices.max(by: { $0.eurPerKWh < $1.eurPerKWh })?.date ?? fallbackDate,
        minimum: prices.map(\.eurPerKWh).min() ?? 0,
        minimumHour: prices.min(by: { $0.eurPerKWh < $1.eurPerKWh })?.date ?? fallbackDate
      )
    )
  }
}
