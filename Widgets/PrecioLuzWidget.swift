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
        let now = Date()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
        let entry = PrecioLuzWidgetEntry(date: now, model: .previewContent)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
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
