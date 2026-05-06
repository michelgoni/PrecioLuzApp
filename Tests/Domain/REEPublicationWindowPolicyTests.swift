import Foundation
import Testing

@testable import PrecioLuzApp

struct REEPublicationWindowPolicyTests {
  private let timeZone = TimeZone(identifier: "Europe/Madrid") ?? .current

  @Test("Policy is pre-cutoff at 20:29 and post-cutoff at 20:30")
  func cutoffBoundary() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let policy = REEPublicationWindowPolicy(calendar: calendar, timeZone: timeZone)

    let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 6)))
    let twentyTwentyNine = try #require(
      calendar.date(bySettingHour: 20, minute: 29, second: 0, of: day)
    )
    let twentyThirty = try #require(
      calendar.date(bySettingHour: 20, minute: 30, second: 0, of: day)
    )
    let twentyThirtyOne = try #require(
      calendar.date(bySettingHour: 20, minute: 31, second: 0, of: day)
    )

    #expect(policy.hasReachedCutoff(now: twentyTwentyNine) == false)
    #expect(policy.hasReachedCutoff(now: twentyThirty) == true)
    #expect(policy.hasReachedCutoff(now: twentyThirtyOne) == true)
  }

  @Test("Policy requests today plus tomorrow from 20:30 onward")
  func dayStartsToLoadAtCutoff() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let policy = REEPublicationWindowPolicy(calendar: calendar, timeZone: timeZone)

    let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 6)))
    let beforeCutoff = try #require(calendar.date(bySettingHour: 20, minute: 29, second: 0, of: day))
    let afterCutoff = try #require(calendar.date(bySettingHour: 20, minute: 30, second: 0, of: day))

    let beforeDayStarts = policy.dayStartsToLoad(now: beforeCutoff, requestedDay: nil)
    let afterDayStarts = policy.dayStartsToLoad(now: afterCutoff, requestedDay: nil)

    #expect(beforeDayStarts.count == 1)
    #expect(afterDayStarts.count == 2)
    #expect(calendar.isDate(afterDayStarts[0], inSameDayAs: day))
    #expect(calendar.isDate(afterDayStarts[1], inSameDayAs: day.addingTimeInterval(86_400)))
  }
}
