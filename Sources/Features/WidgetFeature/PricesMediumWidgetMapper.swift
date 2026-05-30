import Foundation

enum PricesMediumWidgetMapper {
    static func makeModel(
        from hourlyPrices: [HourlyPrice],
        now: Date,
        calendar: Calendar
    ) -> PricesMediumWidgetPresentationModel {
        let sortedPrices = hourlyPrices.sorted { $0.date < $1.date }
        guard
            let currentHour = sortedPrices.first(
                where: { calendar.isDate($0.date, equalTo: now, toGranularity: .hour) }
            ),
            let currentIndex = sortedPrices.firstIndex(where: { $0.date == currentHour.date })
        else {
            return PricesMediumWidgetPresentationModel(
                barSeries: [],
                currentPriceText: "—",
                currentSlotLabel: String(localized: "widget.medium.empty.slot"),
                nextHours: [],
                state: .empty,
                timeWindowLabel: String(localized: "widget.medium.empty.timeWindow")
            )
        }

        let currentAndUpcoming = Array(sortedPrices[currentIndex...])
        let chartSource = Array(currentAndUpcoming.prefix(Constants.chartHours))
        let nextHours = Array(currentAndUpcoming.dropFirst().prefix(Constants.nextHoursCount))

        return PricesMediumWidgetPresentationModel(
            barSeries: normalizedBars(from: chartSource),
            currentPriceText: formatPriceValue(currentHour.eurPerKWh),
            currentSlotLabel: classificationLabel(currentHour.classification),
            nextHours: nextHours.map {
                PricesMediumWidgetPresentationModel.NextHourEntry(
                    hourText: formatHour($0.date, calendar: calendar),
                    level: widgetLevel(from: $0.classification),
                    priceText: formatPriceValue($0.eurPerKWh)
                )
            },
            state: .content,
            timeWindowLabel: [
                formatHour(currentHour.date, calendar: calendar),
                String(localized: "prices.hourly.current.badge")
            ].joined(separator: " · ")
        )
    }

    private static func classificationLabel(_ classification: PriceClassification) -> String {
        switch classification {
        case .cheap:
            String(localized: "prices.classification.cheap")
        case .expensive:
            String(localized: "prices.classification.expensive")
        case .mid:
            String(localized: "prices.classification.mid")
        }
    }

    private static func formatHour(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func formatPriceValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.minimumFractionDigits = Constants.priceFractionDigits
        formatter.maximumFractionDigits = Constants.priceFractionDigits
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0,000"
    }

    private static func normalizedBars(
        from prices: [HourlyPrice]
    ) -> [PricesMediumWidgetPresentationModel.BarEntry] {
        guard let minValue = prices.map(\.eurPerKWh).min(), let maxValue = prices.map(\.eurPerKWh).max() else {
            return []
        }
        let range = maxValue - minValue
        return prices.map { price in
            let normalizedHeight: CGFloat
            if range <= .ulpOfOne {
                normalizedHeight = Constants.flatNormalizedHeight
            } else {
                let normalized = (price.eurPerKWh - minValue) / range
                normalizedHeight = CGFloat(max(Constants.minNormalizedHeight, normalized))
            }
            return PricesMediumWidgetPresentationModel.BarEntry(
                level: widgetLevel(from: price.classification),
                normalizedHeight: normalizedHeight
            )
        }
    }

    private static func widgetLevel(from classification: PriceClassification) -> WidgetPriceLevel {
        switch classification {
        case .cheap:
            .cheap
        case .expensive:
            .expensive
        case .mid:
            .mid
        }
    }
}

private enum Constants {
    static let chartHours = 12
    static let flatNormalizedHeight: CGFloat = 0.6
    static let minNormalizedHeight: Double = 0.2
    static let nextHoursCount = 3
    static let priceFractionDigits = 3
}
