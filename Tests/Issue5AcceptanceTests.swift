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
