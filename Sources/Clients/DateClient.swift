import ComposableArchitecture
import Foundation

struct DateClient: Sendable {
  var now: @Sendable () -> Date
  var calendar: @Sendable () -> Calendar
  var timeZone: @Sendable () -> TimeZone
}

extension DateClient: DependencyKey {
  static let liveValue = DateClient(
    now: { Date() },
    calendar: { Calendar(identifier: .gregorian) },
    timeZone: { TimeZone(identifier: "Europe/Madrid") ?? .current }
  )

  static let testValue = DateClient(
    now: { Date(timeIntervalSince1970: .zero) },
    calendar: { Calendar(identifier: .gregorian) },
    timeZone: { TimeZone(secondsFromGMT: .zero) ?? .current }
  )
}

extension DependencyValues {
  var dateClient: DateClient {
    get { self[DateClient.self] }
    set { self[DateClient.self] = newValue }
  }
}
