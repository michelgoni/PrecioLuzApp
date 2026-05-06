import Foundation

struct REEPublicationWindowPolicy: Sendable {
    static let cutoffHour = 20
    static let cutoffMinute = 30

    var calendar: Calendar
    var timeZone: TimeZone

    func hasReachedCutoff(now: Date) -> Bool {
        var localCalendar = calendar
        localCalendar.timeZone = timeZone

        let dayStart = localCalendar.startOfDay(for: now)
        guard let cutoff = localCalendar.date(
            bySettingHour: Self.cutoffHour,
            minute: Self.cutoffMinute,
            second: 0,
            of: dayStart
        ) else {
            return false
        }
        return now >= cutoff
    }

    func dayStartsToLoad(now: Date, requestedDay: Date?) -> [Date] {
        var localCalendar = calendar
        localCalendar.timeZone = timeZone

        let baseDayStart = localCalendar.startOfDay(for: requestedDay ?? now)
        guard requestedDay == nil else {
            return [baseDayStart]
        }

        guard hasReachedCutoff(now: now),
              let nextDayStart = localCalendar.date(byAdding: .day, value: 1, to: baseDayStart)
        else {
            return [baseDayStart]
        }

        return [baseDayStart, nextDayStart]
    }
}
