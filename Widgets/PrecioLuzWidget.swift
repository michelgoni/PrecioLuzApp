import SwiftUI
import WidgetKit

struct PrecioLuzWidgetEntry: TimelineEntry {
    let date: Date
    let model: PricesMediumWidgetPresentationModel
}

struct PrecioLuzWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrecioLuzWidgetEntry {
        PrecioLuzWidgetEntry(date: Date(), model: .previewContent)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrecioLuzWidgetEntry) -> Void) {
        completion(PrecioLuzWidgetEntry(date: Date(), model: .previewContent))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrecioLuzWidgetEntry>) -> Void) {
        let completion = PrecioLuzWidgetTimelineCompletion(completion)
        Task {
            let entries = await PrecioLuzWidgetTimelineLoader.makeHourlyEntries()
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion.callAsFunction(timeline)
        }
    }
}

struct PrecioLuzHomeWidget: Widget {
    let kind = "PrecioLuzHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrecioLuzWidgetProvider()) { entry in
            PricesMediumWidgetView(model: entry.model)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("AhorraLuzApp")
        .description(String(localized: "widget.medium.empty.subtitle"))
        .supportedFamilies([.systemMedium])
    }
}

@main
struct PrecioLuzWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrecioLuzHomeWidget()
    }
}

private extension PricesMediumWidgetPresentationModel {
    static let previewContent = PricesMediumWidgetPresentationModel(
        barSeries: [
            .init(level: .cheap, normalizedHeight: 0.22),
            .init(level: .cheap, normalizedHeight: 0.31),
            .init(level: .mid, normalizedHeight: 0.42),
            .init(level: .mid, normalizedHeight: 0.52),
            .init(level: .cheap, normalizedHeight: 0.37),
            .init(level: .expensive, normalizedHeight: 0.74),
            .init(level: .mid, normalizedHeight: 0.48),
            .init(level: .cheap, normalizedHeight: 0.29),
            .init(level: .mid, normalizedHeight: 0.45),
            .init(level: .expensive, normalizedHeight: 0.81),
            .init(level: .mid, normalizedHeight: 0.51),
            .init(level: .cheap, normalizedHeight: 0.34),
        ],
        currentPriceText: "0,048",
        currentSlotLabel: "Península",
        nextHours: [
            .init(hourText: "10h", level: .cheap, priceText: "0,017 €/kWh"),
            .init(hourText: "11h", level: .mid, priceText: "0,064 €/kWh"),
            .init(hourText: "12h", level: .expensive, priceText: "0,172 €/kWh"),
        ],
        state: .content,
        timeWindowLabel: "Hoy"
    )
}

private final class PrecioLuzWidgetTimelineCompletion: @unchecked Sendable {
    private let completion: (Timeline<PrecioLuzWidgetEntry>) -> Void

    init(_ completion: @escaping (Timeline<PrecioLuzWidgetEntry>) -> Void) {
        self.completion = completion
    }

    func callAsFunction(_ timeline: Timeline<PrecioLuzWidgetEntry>) {
        completion(timeline)
    }
}

private enum PrecioLuzWidgetTimelineLoader {
    private static let timeZone = TimeZone(identifier: "Europe/Madrid") ?? .current

    static func makeHourlyEntries(now: Date = Date()) async -> [PrecioLuzWidgetEntry] {
        let calendar = pricingCalendar
        let hourlyPrices = await fetchHourlyPrices(now: now, calendar: calendar)
        guard !hourlyPrices.isEmpty else {
            return [PrecioLuzWidgetEntry(date: now, model: makeEmptyModel())]
        }

        let startDate = alignedHourDate(for: now, calendar: calendar) ?? now
        let entryDates = hourlyPrices
            .map(\.date)
            .filter { $0 >= startDate }
            .sorted()

        guard !entryDates.isEmpty else {
            return [PrecioLuzWidgetEntry(date: now, model: makeEmptyModel())]
        }

        return entryDates.map { cursor in
            let model = PricesMediumWidgetMapper.makeModel(
                from: hourlyPrices,
                now: cursor,
                calendar: calendar
            )
            return PrecioLuzWidgetEntry(date: cursor, model: model)
        }
    }

    private static func fetchHourlyPrices(now: Date, calendar: Calendar) async -> [HourlyPrice] {
        do {
            let rawPrices = try await fetchRawPrices(now: now, calendar: calendar)
            return HourlyPriceClassifier.classify(rawPrices, calendar: calendar)
        } catch {
            return []
        }
    }

    private static func makeEmptyModel() -> PricesMediumWidgetPresentationModel {
        PricesMediumWidgetPresentationModel(
            barSeries: [],
            currentPriceText: "—",
            currentSlotLabel: String(localized: "widget.medium.empty.slot"),
            nextHours: [],
            state: .empty,
            timeWindowLabel: String(localized: "widget.medium.empty.timeWindow")
        )
    }

    private static func fetchRawPrices(now: Date, calendar: Calendar) async throws -> [PricingClient.HourPrice] {
        let policy = REEPublicationWindowPolicy(calendar: calendar, timeZone: timeZone)
        let client = PricingClient.esiosLive()
        let dayStarts = policy.dayStartsToLoad(now: now, requestedDay: nil)
        var prices: [PricingClient.HourPrice] = []
        for dayStart in dayStarts {
            prices += try await client.fetchDailyPrices(dayStart, timeZone)
        }
        return prices.sorted { $0.date < $1.date }
    }

    private static var pricingCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func alignedHourDate(for date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        return calendar.date(from: components)
    }
}
