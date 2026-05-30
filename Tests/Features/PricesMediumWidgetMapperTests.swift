import Foundation
import Testing

@testable import PrecioLuzApp

struct PricesMediumWidgetMapperTests {
    @Test("Widget mapper returns empty model when current hour is missing")
    func returnsEmptyModelWhenCurrentHourIsMissing() {
        let calendar = testCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 15))!
        let prices = [
            makeHourlyPrice(calendar: calendar, day: 21, hour: 8, value: 0.121, classification: .mid),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 9, value: 0.137, classification: .expensive)
        ]

        let model = PricesMediumWidgetMapper.makeModel(from: prices, now: now, calendar: calendar)

        #expect(model.state == .empty)
        #expect(model.barSeries.isEmpty)
        #expect(model.nextHours.isEmpty)
        #expect(model.currentPriceText == "—")
    }

    @Test("Widget mapper returns content model with 12 bars and up to 3 next hours")
    func returnsContentModel() {
        let calendar = testCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 5))!
        let prices = (0..<15).map { offset -> HourlyPrice in
            let hour = 10 + offset
            let classification: PriceClassification = switch offset % 3 {
            case 0: .cheap
            case 1: .mid
            default: .expensive
            }
            return makeHourlyPrice(
                calendar: calendar,
                day: hour >= 24 ? 22 : 21,
                hour: hour % 24,
                value: 0.100 + (Double(offset) * 0.01),
                classification: classification
            )
        }

        let model = PricesMediumWidgetMapper.makeModel(from: prices, now: now, calendar: calendar)

        #expect(model.state == .content)
        #expect(model.barSeries.count == 12)
        #expect(model.nextHours.count == 3)
        #expect(model.timeWindowLabel.contains("Ahora"))
        #expect(model.currentSlotLabel == "Barato")
    }

    @Test("Widget mapper normalizes bar heights with floor")
    func normalizesBarsWithFloor() {
        let calendar = testCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 0))!
        let prices = [
            makeHourlyPrice(calendar: calendar, day: 21, hour: 10, value: 0.100, classification: .cheap),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 11, value: 0.101, classification: .mid),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 12, value: 0.200, classification: .expensive)
        ]

        let model = PricesMediumWidgetMapper.makeModel(from: prices, now: now, calendar: calendar)
        let heights = model.barSeries.map(\.normalizedHeight)

        #expect(heights.allSatisfy { $0 >= 0.2 })
    }

    @Test("Widget mapper keeps stable normalized height when all values are equal")
    func normalizesBarsForFlatSeries() {
        let calendar = testCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 0))!
        let prices = [
            makeHourlyPrice(calendar: calendar, day: 21, hour: 10, value: 0.111, classification: .cheap),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 11, value: 0.111, classification: .mid),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 12, value: 0.111, classification: .expensive)
        ]

        let model = PricesMediumWidgetMapper.makeModel(from: prices, now: now, calendar: calendar)
        let heights = model.barSeries.map(\.normalizedHeight)

        #expect(heights == [0.6, 0.6, 0.6])
    }

    @Test("Widget mapper sorts unsorted input before computing current and next hours")
    func sortsInputBeforeComputingCurrentAndNextHours() {
        let calendar = testCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 30))!
        let unsortedPrices = [
            makeHourlyPrice(calendar: calendar, day: 21, hour: 12, value: 0.181, classification: .expensive),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 10, value: 0.129, classification: .cheap),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 11, value: 0.150, classification: .mid),
            makeHourlyPrice(calendar: calendar, day: 21, hour: 13, value: 0.142, classification: .mid)
        ]

        let model = PricesMediumWidgetMapper.makeModel(from: unsortedPrices, now: now, calendar: calendar)

        #expect(model.state == .content)
        #expect(model.currentPriceText == "0,129")
        #expect(model.nextHours.map(\.hourText) == ["11:00", "12:00", "13:00"])
        #expect(model.nextHours.map(\.priceText) == ["0,150", "0,181", "0,142"])
    }

    @Test("Widget mapper formats hours using the injected pricing calendar time zone")
    func formatsHoursUsingInjectedCalendarTimeZone() {
        var honoluluCalendar = Calendar(identifier: .gregorian)
        honoluluCalendar.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = utcCalendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 10, minute: 0))!
        let prices = [
            HourlyPrice(
                classification: .cheap,
                date: now,
                daypart: Daypart.from(date: now, calendar: honoluluCalendar),
                eurPerKWh: 0.101
            ),
            HourlyPrice(
                classification: .mid,
                date: now.addingTimeInterval(3600),
                daypart: Daypart.from(date: now.addingTimeInterval(3600), calendar: honoluluCalendar),
                eurPerKWh: 0.121
            )
        ]

        let model = PricesMediumWidgetMapper.makeModel(from: prices, now: now, calendar: honoluluCalendar)

        #expect(model.state == .content)
        #expect(model.timeWindowLabel.hasPrefix("00:00"))
        #expect(model.nextHours.map(\.hourText) == ["01:00"])
    }
}

private extension PricesMediumWidgetMapperTests {
    var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    func makeHourlyPrice(
        calendar: Calendar,
        day: Int,
        hour: Int,
        value: Double,
        classification: PriceClassification
    ) -> HourlyPrice {
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: day, hour: hour))!
        return HourlyPrice(
            classification: classification,
            date: date,
            daypart: Daypart.from(date: date, calendar: calendar),
            eurPerKWh: value
        )
    }
}
