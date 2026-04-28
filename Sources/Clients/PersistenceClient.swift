import ComposableArchitecture
import Foundation

struct PersistenceClient: Sendable {
  var loadNotificationSettings: @Sendable () async throws -> NotificationSettings?
  var loadSnapshot: @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> DailySnapshot?
  var saveNotificationSettings: @Sendable (_ settings: NotificationSettings) async throws -> Void
  var saveSnapshot: @Sendable (_ snapshot: DailySnapshot) async throws -> Void
  var pruneSnapshots: @Sendable (_ keepLastDays: Int) async throws -> Void

  init(
    loadNotificationSettings: @escaping @Sendable () async throws -> NotificationSettings? = { nil },
    loadSnapshot: @escaping @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> DailySnapshot?,
    saveNotificationSettings: @escaping @Sendable (_ settings: NotificationSettings) async throws -> Void = { _ in },
    saveSnapshot: @escaping @Sendable (_ snapshot: DailySnapshot) async throws -> Void,
    pruneSnapshots: @escaping @Sendable (_ keepLastDays: Int) async throws -> Void
  ) {
    self.loadNotificationSettings = loadNotificationSettings
    self.loadSnapshot = loadSnapshot
    self.saveNotificationSettings = saveNotificationSettings
    self.saveSnapshot = saveSnapshot
    self.pruneSnapshots = pruneSnapshots
  }
}

extension PersistenceClient {
  struct DailySnapshot: Equatable, Sendable {
    var dayStart: Date
    var fetchedAt: Date
    var hourlyPrices: [PricingClient.HourPrice]
  }
}

extension PersistenceClient: DependencyKey {
  private static let notificationSettingsDefaultsKey = "notificationSettings.defaults.v1"

  static let liveValue = PersistenceClient(
    loadNotificationSettings: {
      let data = UserDefaults.standard.data(forKey: notificationSettingsDefaultsKey)
      guard let data else { return nil }
      return try JSONDecoder().decode(NotificationSettings.self, from: data)
    },
    loadSnapshot: { _, _ in nil },
    saveNotificationSettings: { settings in
      let data = try JSONEncoder().encode(settings)
      UserDefaults.standard.set(data, forKey: notificationSettingsDefaultsKey)
    },
    saveSnapshot: { _ in },
    pruneSnapshots: { _ in }
  )

  static let testValue = PersistenceClient(
    loadNotificationSettings: { nil },
    loadSnapshot: { _, _ in nil },
    saveNotificationSettings: { _ in },
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
