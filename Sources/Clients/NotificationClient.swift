import ComposableArchitecture
import Foundation
import UserNotifications

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
    authorizationStatus: {
      let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
      switch status {
      case .authorized, .ephemeral, .provisional:
        return .authorized
      case .denied:
        return .denied
      case .notDetermined:
        return .notDetermined
      @unknown default:
        return .notDetermined
      }
    },
    requestAuthorization: {
      try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    },
    schedule: { requests in
      let center = UNUserNotificationCenter.current()
      center.removeAllDeliveredNotifications()
      center.removeAllPendingNotificationRequests()

      for request in requests {
        let content = UNMutableNotificationContent()
        content.body = request.body
        content.sound = .default
        content.title = request.title

        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second],
          from: request.triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let notificationRequest = UNNotificationRequest(
          identifier: request.id,
          content: content,
          trigger: trigger
        )
        try await center.add(notificationRequest)
      }
    }
  )

  static let testValue = NotificationClient(
    authorizationStatus: { .authorized },
    requestAuthorization: { true },
    schedule: { _ in }
  )
}

private extension UNUserNotificationCenter {
  func add(_ request: UNNotificationRequest) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      add(request) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }
}

extension DependencyValues {
  var notificationClient: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}
