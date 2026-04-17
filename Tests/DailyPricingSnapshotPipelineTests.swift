import Foundation
import Testing

@testable import PrecioLuzApp

struct DailyPricingSnapshotPipelineTests {
  @Test("Pipeline returns fresh data, persists snapshot and prunes retention window")
  func freshResultPersistsAndPrunes() async throws {
    let recorder = PersistenceRecorder()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)
    let timeZone = dateClient.timeZone()
    var calendar = dateClient.calendar()
    calendar.timeZone = timeZone
    let dayStart = calendar.startOfDay(for: now)
    let rawPrices = makeRawPrices(dayStart: dayStart, timeZone: timeZone)

    let pricingClient = PricingClient { _, _ in rawPrices }
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

    #expect(payload.dayStart == dayStart)
    #expect(payload.fetchedAt == now)
    #expect(payload.hourlyPrices.count == rawPrices.count)
    #expect(payload.summary != nil)
    #expect(await recorder.loadCount == 0)
    #expect(await recorder.savedSnapshots.count == 1)
    #expect(await recorder.pruneCalls == [30])
  }

  @Test("Pipeline falls back to cached snapshot when fetch fails")
  func cachedFallbackWhenFetchFails() async throws {
    let recorder = PersistenceRecorder()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)
    let timeZone = dateClient.timeZone()
    var calendar = dateClient.calendar()
    calendar.timeZone = timeZone
    let dayStart = calendar.startOfDay(for: now)
    let cachedPrices = makeRawPrices(dayStart: dayStart, timeZone: timeZone)
    let cachedSnapshot = PersistenceClient.DailySnapshot(
      dayStart: dayStart,
      fetchedAt: now.addingTimeInterval(-3600),
      hourlyPrices: cachedPrices
    )

    enum TestError: Error { case offline }

    let pricingClient = PricingClient { _, _ in throw TestError.offline }
    let persistenceClient = PersistenceClient(
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
    let pipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: persistenceClient,
      pricingClient: pricingClient
    )

    let result = await pipeline.load()

    guard case let .cached(payload) = result else {
      Issue.record("Expected cached result.")
      return
    }

    #expect(payload.dayStart == cachedSnapshot.dayStart)
    #expect(payload.fetchedAt == cachedSnapshot.fetchedAt)
    #expect(payload.hourlyPrices.count == cachedPrices.count)
    #expect(await recorder.loadCount == 1)
    #expect(await recorder.savedSnapshots.isEmpty)
    #expect(await recorder.pruneCalls.isEmpty)
  }

  @Test("Pipeline returns failed when fetch and cache both fail")
  func failedWhenNoCacheAvailable() async {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)

    enum TestError: Error { case offline }

    let pricingClient = PricingClient { _, _ in throw TestError.offline }
    let persistenceClient = PersistenceClient(
      loadSnapshot: { _, _ in nil },
      saveSnapshot: { _ in },
      pruneSnapshots: { _ in }
    )
    let pipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: persistenceClient,
      pricingClient: pricingClient
    )

    let result = await pipeline.load()
    #expect(result == .failed)
  }

  @Test("Pipeline still returns fresh when persistence operations fail")
  func persistenceFailuresDoNotPreventFreshResult() async throws {
    enum TestError: Error { case diskFailure }

    let recorder = PersistenceRecorder()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dateClient = makeDateClient(now: now)
    let timeZone = dateClient.timeZone()
    var calendar = dateClient.calendar()
    calendar.timeZone = timeZone
    let dayStart = calendar.startOfDay(for: now)
    let rawPrices = makeRawPrices(dayStart: dayStart, timeZone: timeZone)

    let pricingClient = PricingClient { _, _ in rawPrices }
    let persistenceClient = PersistenceClient(
      loadSnapshot: { _, _ in
        await recorder.recordLoad()
        return nil
      },
      saveSnapshot: { _ in
        throw TestError.diskFailure
      },
      pruneSnapshots: { _ in
        throw TestError.diskFailure
      }
    )
    let pipeline = DailyPricingSnapshotPipeline(
      dateClient: dateClient,
      persistenceClient: persistenceClient,
      pricingClient: pricingClient
    )

    let result = await pipeline.load()
    guard case let .fresh(payload) = result else {
      Issue.record("Expected fresh result despite persistence failures.")
      return
    }

    #expect(payload.dayStart == dayStart)
    #expect(payload.hourlyPrices.count == rawPrices.count)
    #expect(await recorder.loadCount == 0)
  }

  private func makeDateClient(now: Date) -> DateClient {
    DateClient(
      now: { now },
      calendar: { Calendar(identifier: .gregorian) },
      timeZone: { TimeZone(secondsFromGMT: .zero) ?? .current }
    )
  }

  private func makeRawPrices(dayStart: Date, timeZone: TimeZone) -> [PricingClient.HourPrice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone

    return (0..<24).compactMap { hour in
      guard let date = calendar.date(byAdding: .hour, value: hour, to: dayStart) else { return nil }
      let price = 0.10 + (Double(hour) * 0.01)
      return .init(date: date, eurPerKWh: price)
    }
  }
}

private actor PersistenceRecorder {
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
