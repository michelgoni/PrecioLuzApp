import Foundation

enum NotificationSchedulingPlanner {
    static let leadTimeInterval: TimeInterval = 15 * 60

    struct PlanItem: Equatable, Sendable {
        enum Kind: Equatable, Sendable {
            case dailyMaximum
            case dailyMinimum
            case threshold
        }

        var hour: HourlyPrice
        var kind: Kind
        var triggerDate: Date
    }

    static func makePlan(hourlyPrices: [HourlyPrice], settings: NotificationSettings, now: Date, calendar: Calendar) -> [PlanItem] {
        guard settings.notificationsEnabled else {
            return []
        }

        let futureSameDayPrices = hourlyPrices.filter {
            $0.date > now && calendar.isDate($0.date, inSameDayAs: now)
        }
        guard !futureSameDayPrices.isEmpty else {
            return []
        }

        var plan: [PlanItem] = []

        if settings.notifyDailyMinimum,
           let minimumHour = futureSameDayPrices.min(by: { $0.eurPerKWh < $1.eurPerKWh }) {
            plan.append(
                PlanItem(
                    hour: minimumHour,
                    kind: .dailyMinimum,
                    triggerDate: triggerDate(for: minimumHour.date, now: now)
                )
            )
        }

        if settings.notifyDailyMaximum,
           let maximumHour = futureSameDayPrices.max(by: { $0.eurPerKWh < $1.eurPerKWh }) {
            plan.append(
                PlanItem(
                    hour: maximumHour,
                    kind: .dailyMaximum,
                    triggerDate: triggerDate(for: maximumHour.date, now: now)
                )
            )
        }

        if settings.customThresholdEnabled,
           let threshold = settings.customThresholdEURPerKWh {
            let thresholdHours = futureSameDayPrices.filter { $0.eurPerKWh <= threshold }
            plan.append(
                contentsOf: thresholdHours.map {
                    PlanItem(
                        hour: $0,
                        kind: .threshold,
                        triggerDate: triggerDate(for: $0.date, now: now)
                    )
                }
            )
        }

        return plan.sorted(by: { $0.triggerDate < $1.triggerDate })
    }

    private static func triggerDate(for targetHourDate: Date, now: Date) -> Date {
        let proposedTriggerDate = targetHourDate.addingTimeInterval(-leadTimeInterval)
        return proposedTriggerDate > now ? proposedTriggerDate : now
    }
}
