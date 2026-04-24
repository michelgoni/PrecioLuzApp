import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct Issue5AcceptanceTests {
  @Test("Acceptance #5: fresh snapshot integrates derived values, cost and retention policy")
  func freshSnapshotIntegration() async throws {
    let recorder = AcceptancePipelineRecorder()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)
    let timeZone = dateClient.timeZone()
    var calendar = dateClient.calendar()
    calendar.timeZone = timeZone
    let dayStart = calendar.startOfDay(for: now)
    let rawPrices = makeHourlyPrices(dayStart: dayStart, timeZone: timeZone)
    let persistenceClient = PersistenceClient(
      loadSnapshot: { _, _ in
        await recorder.recordLoad()
        return nil
      },
      saveSnapshot: { snapshot in
        await recorder.recordSave(snapshot)
      },
      pruneSnapshots: { keepLastDays in
        await recorder.recordPrune(keepLastDays)
      }
    )
    let pricingClient = PricingClient { _, _ in rawPrices }
    let pipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: persistenceClient,
      pricingClient: pricingClient
    )

    let result = await pipeline.load()
    guard case let .fresh(payload) = result else {
      Issue.record("Expected fresh result.")
      return
    }

    let currentHour = try #require(payload.summary?.current)
    let preset = AppliancePreset(
      displayName: "Dishwasher",
      kind: .dishwasher,
      powerKW: 1.4,
      shortDescription: "Standard cycle",
      symbolName: "dishwasher"
    )
    let cost = ApplianceCostEstimator.estimate(durationHours: 1.5, preset: preset, selectedHour: currentHour)
    let expectedCost = currentHour.eurPerKWh * preset.powerKW * 1.5
    let epsilon = 0.000_001

    #expect(payload.hourlyPrices.count == 24)
    #expect(payload.summary != nil)
    #expect(abs(cost.estimatedCostEUR - expectedCost) < epsilon)
    #expect(await recorder.loadCount == 0)
    #expect(await recorder.savedSnapshots.count == 1)
    #expect(await recorder.pruneCalls == [30])
  }

  @Test("Acceptance #5: offline behavior uses cache and fails when cache is missing")
  func offlineBehavior() async {
    let recorder = AcceptancePipelineRecorder()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)
    let timeZone = dateClient.timeZone()
    var calendar = dateClient.calendar()
    calendar.timeZone = timeZone
    let dayStart = calendar.startOfDay(for: now)
    let cachedSnapshot = PersistenceClient.DailySnapshot(
      dayStart: dayStart,
      fetchedAt: now.addingTimeInterval(-3600),
      hourlyPrices: makeHourlyPrices(dayStart: dayStart, timeZone: timeZone)
    )

    await verifyCachedFallback(
      cachedSnapshot: cachedSnapshot,
      dateClient: dateClient,
      dayStart: dayStart,
      recorder: recorder
    )
    await verifyOfflineFailureWithoutCache(dateClient: dateClient)
  }

  private func makeDateClient(now: Date) -> DateClient {
    DateClient(
      now: { now },
      calendar: { Calendar(identifier: .gregorian) },
      timeZone: { TimeZone(secondsFromGMT: .zero) ?? .current }
    )
  }

  private func makeHourlyPrices(dayStart: Date, timeZone: TimeZone) -> [PricingClient.HourPrice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone

    return (0..<24).compactMap { hour in
      guard let date = calendar.date(byAdding: .hour, value: hour, to: dayStart) else { return nil }
      return .init(date: date, eurPerKWh: 0.10 + (Double(hour) * 0.01))
    }
  }

  private func verifyCachedFallback(
    cachedSnapshot: PersistenceClient.DailySnapshot,
    dateClient: DateClient,
    dayStart: Date,
    recorder: AcceptancePipelineRecorder
  ) async {
    enum TestError: Error { case offline }

    let cachedPersistence = PersistenceClient(
      loadSnapshot: { _, _ in
        await recorder.recordLoad()
        return cachedSnapshot
      },
      saveSnapshot: { snapshot in
        await recorder.recordSave(snapshot)
      },
      pruneSnapshots: { keepLastDays in
        await recorder.recordPrune(keepLastDays)
      }
    )
    let failingPricing = PricingClient { _, _ in throw TestError.offline }
    let cachedPipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: cachedPersistence,
      pricingClient: failingPricing
    )
    let cachedResult = await cachedPipeline.load()

    guard case let .cached(payload) = cachedResult else {
      Issue.record("Expected cached result.")
      return
    }

    #expect(payload.dayStart == dayStart)
    #expect(payload.summary != nil)
    #expect(await recorder.loadCount == 1)
    #expect(await recorder.savedSnapshots.isEmpty)
    #expect(await recorder.pruneCalls.isEmpty)
  }

  private func verifyOfflineFailureWithoutCache(dateClient: DateClient) async {
    enum TestError: Error { case offline }

    let emptyPersistence = PersistenceClient(
      loadSnapshot: { _, _ in nil },
      saveSnapshot: { _ in },
      pruneSnapshots: { _ in }
    )
    let failingPricing = PricingClient { _, _ in throw TestError.offline }
    let failedPipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: emptyPersistence,
      pricingClient: failingPricing
    )

    #expect(await failedPipeline.load() == .failed)
  }
}

struct Issue7AcceptanceTests {
  @MainActor
  @Test("Acceptance #7: fresh pricing flow supports time-slot selection and modal lifecycle")
  func freshPricingSelectionFlow() async {
    let payload = DailyPricingSnapshotPayload.issue7Payload
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

    await store.send(.pricesDurationHoursChanged(2.0)) {
      $0.prices.costCalculation.durationHours = 2.0
    }

    await store.send(.pricesPresetSelected(.dishwasher)) {
      $0.prices.costCalculation.selectedPresetKind = .dishwasher
    }

    await store.send(.pricesCalculationPlaceholderDismissed) {
      $0.prices.costCalculation.isPresented = false
    }
  }

  @MainActor
  @Test("Acceptance #7: cached pricing flow marks cache state for shell and prices")
  func cachedPricingFlowMarksCacheState() async {
    let payload = DailyPricingSnapshotPayload.issue7Payload
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.snapshotResponse(.cached(payload))) {
      $0.prices.hourlyPrices = payload.hourlyPrices
      $0.prices.isFromCache = true
      $0.prices.summary = payload.summary
      $0.rootStatus = .cached
    }
  }
}

private extension DailyPricingSnapshotPayload {
  static var issue7Payload: Self {
    let prices = [
      HourlyPrice(
        classification: .cheap,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        daypart: .morning,
        eurPerKWh: 0.10
      ),
      HourlyPrice(
        classification: .mid,
        date: Date(timeIntervalSince1970: 1_700_003_600),
        daypart: .morning,
        eurPerKWh: 0.158
      ),
      HourlyPrice(
        classification: .expensive,
        date: Date(timeIntervalSince1970: 1_700_007_200),
        daypart: .afternoon,
        eurPerKWh: 0.215
      ),
    ]

    return Self(
      dayStart: Date(timeIntervalSince1970: 1_699_996_400),
      fetchedAt: Date(timeIntervalSince1970: 1_700_010_800),
      hourlyPrices: prices,
      summary: PriceSummary(
        average: 0.158,
        current: prices[1],
        maximum: 0.215,
        maximumHour: prices[2].date,
        minimum: 0.10,
        minimumHour: prices[0].date
      )
    )
  }
}

private actor AcceptancePipelineRecorder {
  private(set) var loadCount = 0
  private(set) var pruneCalls: [Int] = []
  private(set) var savedSnapshots: [PersistenceClient.DailySnapshot] = []

  func recordLoad() {
    loadCount += 1
  }

  func recordPrune(_ keepLastDays: Int) {
    pruneCalls.append(keepLastDays)
  }

  func recordSave(_ snapshot: PersistenceClient.DailySnapshot) {
    savedSnapshots.append(snapshot)
  }
}
