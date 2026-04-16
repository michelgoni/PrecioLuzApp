import ComposableArchitecture
import Foundation

struct NotificationClient: Sendable {
  var authorizationStatus: @Sendable () async -> AuthorizationStatus
  var requestAuthorization: @Sendable () async throws -> Bool
  var schedule: @Sendable (_ requests: [Request]) async throws -> Void
}

extension NotificationClient {
  enum AuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
  }

  struct Request: Equatable, Sendable {
    var id: String
    var title: String
    var body: String
    var triggerDate: Date
  }
}

extension NotificationClient: DependencyKey {
  static let liveValue = NotificationClient(
    authorizationStatus: { .notDetermined },
    requestAuthorization: { false },
    schedule: { _ in }
  )

  static let testValue = NotificationClient(
    authorizationStatus: { .authorized },
    requestAuthorization: { true },
    schedule: { _ in }
  )
}

extension DependencyValues {
  var notificationClient: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}
