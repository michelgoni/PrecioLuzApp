import ComposableArchitecture
import Foundation

struct PersistenceClient: Sendable {
  var loadSnapshot: @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> DailySnapshot?
  var saveSnapshot: @Sendable (_ snapshot: DailySnapshot) async throws -> Void
  var pruneSnapshots: @Sendable (_ keepLastDays: Int) async throws -> Void
}

extension PersistenceClient {
  struct DailySnapshot: Equatable, Sendable {
    var dayStart: Date
    var fetchedAt: Date
    var hourlyPrices: [PricingClient.HourPrice]
  }
}

extension PersistenceClient: DependencyKey {
  static let liveValue = PersistenceClient(
    loadSnapshot: { _, _ in nil },
    saveSnapshot: { _ in },
    pruneSnapshots: { _ in }
  )

  static let testValue = PersistenceClient(
    loadSnapshot: { _, _ in nil },
    saveSnapshot: { _ in },
    pruneSnapshots: { _ in }
  )
}

extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}
