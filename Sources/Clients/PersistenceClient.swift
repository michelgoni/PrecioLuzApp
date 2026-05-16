import ComposableArchitecture
import Foundation

struct PersistenceClient: Sendable {
  var loadOnboardingCompleted: @Sendable () async throws -> Bool
  var loadNotificationSettings: @Sendable () async throws -> NotificationSettings?
  var loadSnapshot: @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> DailySnapshot?
  var saveOnboardingCompleted: @Sendable (_ completed: Bool) async throws -> Void
  var saveNotificationSettings: @Sendable (_ settings: NotificationSettings) async throws -> Void
  var saveSnapshot: @Sendable (_ snapshot: DailySnapshot) async throws -> Void
  var pruneSnapshots: @Sendable (_ keepLastDays: Int) async throws -> Void

  init(
    loadOnboardingCompleted: @escaping @Sendable () async throws -> Bool = { false },
    loadNotificationSettings: @escaping @Sendable () async throws -> NotificationSettings? = { nil },
    loadSnapshot: @escaping @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> DailySnapshot?,
    saveOnboardingCompleted: @escaping @Sendable (_ completed: Bool) async throws -> Void = { _ in },
    saveNotificationSettings: @escaping @Sendable (_ settings: NotificationSettings) async throws -> Void = { _ in },
    saveSnapshot: @escaping @Sendable (_ snapshot: DailySnapshot) async throws -> Void,
    pruneSnapshots: @escaping @Sendable (_ keepLastDays: Int) async throws -> Void
  ) {
    self.loadOnboardingCompleted = loadOnboardingCompleted
    self.loadNotificationSettings = loadNotificationSettings
    self.loadSnapshot = loadSnapshot
    self.saveOnboardingCompleted = saveOnboardingCompleted
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
  private static let onboardingCompletedDefaultsKey = "onboarding.completed.v1"

  static let liveValue = PersistenceClient(
    loadOnboardingCompleted: {
      let arguments = ProcessInfo.processInfo.arguments
      if arguments.contains("-PrecioLuzResetOnboarding") {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedDefaultsKey)
        return false
      }
      if arguments.contains("-PrecioLuzOnboardingCompleted") {
        return true
      }
      return UserDefaults.standard.bool(forKey: onboardingCompletedDefaultsKey)
    },
    loadNotificationSettings: {
      let data = UserDefaults.standard.data(forKey: notificationSettingsDefaultsKey)
      guard let data else { return nil }
      return try JSONDecoder().decode(NotificationSettings.self, from: data)
    },
    loadSnapshot: { _, _ in nil },
    saveOnboardingCompleted: { completed in
      UserDefaults.standard.set(completed, forKey: onboardingCompletedDefaultsKey)
    },
    saveNotificationSettings: { settings in
      let data = try JSONEncoder().encode(settings)
      UserDefaults.standard.set(data, forKey: notificationSettingsDefaultsKey)
    },
    saveSnapshot: { _ in },
    pruneSnapshots: { _ in }
  )

  static let testValue = PersistenceClient(
    loadOnboardingCompleted: { false },
    loadNotificationSettings: { nil },
    loadSnapshot: { _, _ in nil },
    saveOnboardingCompleted: { _ in },
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
