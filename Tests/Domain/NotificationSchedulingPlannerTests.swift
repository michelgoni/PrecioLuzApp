import Foundation
import Testing

@testable import PrecioLuzApp

struct NotificationSchedulingPlannerTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now: Date

    init() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        now = calendar.startOfDay(for: base).addingTimeInterval(12 * 3_600)
    }

    @Test("Planner returns empty when notifications are disabled")
    func plannerReturnsEmptyWhenDisabled() {
        var settings = NotificationSettings.productDefaults
        settings.notificationsEnabled = false

        let plan = NotificationSchedulingPlanner.makePlan(
            hourlyPrices: sampleHourlyPrices(),
            settings: settings,
            now: now,
            calendar: calendar
        )

        #expect(plan.isEmpty)
    }

    @Test("Planner schedules only future slots from the same day")
    func plannerUsesOnlyFutureSameDaySlots() {
        var settings = NotificationSettings.productDefaults
        settings.notificationsEnabled = true
        settings.notifyDailyMaximum = false
        settings.notifyDailyMinimum = true

        let yesterdayPrice = HourlyPrice(
            classification: .cheap,
            date: now.addingTimeInterval(-86_400),
            daypart: .morning,
            eurPerKWh: 0.01
        )
        let pastSameDayPrice = HourlyPrice(
            classification: .cheap,
            date: now.addingTimeInterval(-3_600),
            daypart: .morning,
            eurPerKWh: 0.02
        )
        let futureSameDayPrice = HourlyPrice(
            classification: .cheap,
            date: now.addingTimeInterval(3_600),
            daypart: .afternoon,
            eurPerKWh: 0.03
        )

        let plan = NotificationSchedulingPlanner.makePlan(
            hourlyPrices: [yesterdayPrice, pastSameDayPrice, futureSameDayPrice],
            settings: settings,
            now: now,
            calendar: calendar
        )

        #expect(plan.count == 1)
        #expect(plan.first?.hour.date == futureSameDayPrice.date)
    }

    @Test("Planner schedules minimum, maximum and threshold alerts for future slots")
    func plannerSchedulesAllEnabledKinds() {
        var settings = NotificationSettings.productDefaults
        settings.customThresholdEnabled = true
        settings.customThresholdEURPerKWh = 0.18
        settings.notificationsEnabled = true
        settings.notifyDailyMaximum = true
        settings.notifyDailyMinimum = true

        let plan = NotificationSchedulingPlanner.makePlan(
            hourlyPrices: sampleHourlyPrices(),
            settings: settings,
            now: now,
            calendar: calendar
        )

        let minimumCount = plan.filter { $0.kind == .dailyMinimum }.count
        let maximumCount = plan.filter { $0.kind == .dailyMaximum }.count
        let thresholdCount = plan.filter { $0.kind == .threshold }.count

        #expect(minimumCount == 1)
        #expect(maximumCount == 1)
        #expect(thresholdCount == 3)
    }

    @Test("Planner uses ASAP fallback when lead time is already in the past")
    func plannerUsesAsapFallback() {
        var settings = NotificationSettings.productDefaults
        settings.notificationsEnabled = true
        settings.notifyDailyMaximum = false
        settings.notifyDailyMinimum = true

        let slotInTenMinutes = HourlyPrice(
            classification: .cheap,
            date: now.addingTimeInterval(10 * 60),
            daypart: .afternoon,
            eurPerKWh: 0.10
        )

        let plan = NotificationSchedulingPlanner.makePlan(
            hourlyPrices: [slotInTenMinutes],
            settings: settings,
            now: now,
            calendar: calendar
        )

        #expect(plan.count == 1)
        #expect(plan.first?.triggerDate == now)
    }

    private func sampleHourlyPrices() -> [HourlyPrice] {
        [
            HourlyPrice(
                classification: .mid,
                date: now.addingTimeInterval(3_600),
                daypart: .afternoon,
                eurPerKWh: 0.15
            ),
            HourlyPrice(
                classification: .cheap,
                date: now.addingTimeInterval(7_200),
                daypart: .afternoon,
                eurPerKWh: 0.11
            ),
            HourlyPrice(
                classification: .expensive,
                date: now.addingTimeInterval(10_800),
                daypart: .afternoon,
                eurPerKWh: 0.24
            ),
            HourlyPrice(
                classification: .mid,
                date: now.addingTimeInterval(14_400),
                daypart: .night,
                eurPerKWh: 0.18
            ),
        ]
    }
}
