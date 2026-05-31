import Foundation
import SwiftUI

#Preview("Prices placeholder") {
    PricesView(
        onHourTapped: { _ in },
        state: PricesFeature.State()
    )
}

#Preview("Prices loading shimmer") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewLoadingShimmer
    )
    .preferredColorScheme(.dark)
}

#Preview("Prices summary content") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewContent
    )
}

#Preview("Prices cached content") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewCached
    )
}

#Preview("Prices widget content") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewWidgetContent
    )
    .preferredColorScheme(.dark)
}

#Preview("Prices widget empty") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewWidgetEmpty
    )
    .preferredColorScheme(.dark)
}

#Preview("Prices hourly only") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewHourlyOnly
    )
}

#Preview("Prices today + tomorrow (post-20:30)") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewTodayAndTomorrow
    )
}

#Preview("Prices calculation placeholder") {
    PricesView(
        onHourTapped: { _ in },
        state: .previewCalculationSheet
    )
}

private extension PricesFeature.State {
    static var previewLoadingShimmer: Self {
        PricesFeature.State(
            costCalculation: CostCalculationFeature.State(),
            hourlyListPresentationMode: .withDateHeaders,
            hourlyPrices: [],
            isFromCache: false,
            isLoading: true,
            summary: nil,
            visibleHourlyPrices: []
        )
    }

    static var previewCached: Self {
        var state = previewContent
        state.isFromCache = true
        return state
    }

    static var previewContent: Self {
        let prices = [
            HourlyPrice(
                classification: .cheap,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                daypart: .morning,
                eurPerKWh: 0.10
            ),
            HourlyPrice(
                classification: .mid,
                date: Date(timeIntervalSince1970: 1_700_003_600),
                daypart: .morning,
                eurPerKWh: 0.158
            ),
            HourlyPrice(
                classification: .expensive,
                date: Date(timeIntervalSince1970: 1_700_007_200),
                daypart: .afternoon,
                eurPerKWh: 0.215
            )
        ]
        return PricesFeature.State(
            costCalculation: CostCalculationFeature.State(),
            hourlyListPresentationMode: .withDateHeaders,
            hourlyPrices: prices,
            isFromCache: false,
            isLoading: false,
            summary: PriceSummary(
                average: 0.158,
                current: prices[1],
                maximum: 0.215,
                maximumHour: prices[2].date,
                minimum: 0.10,
                minimumHour: prices[0].date
            ),
            visibleHourlyPrices: prices
        )
    }

    static var previewHourlyOnly: Self {
        var state = previewContent
        state.summary = nil
        return state
    }

    static var previewWidgetContent: Self {
        previewContent
    }

    static var previewWidgetEmpty: Self {
        previewHourlyOnly
    }

    static var previewCalculationSheet: Self {
        var state = previewContent
        state.costCalculation.isPresented = true
        state.costCalculation.selectedHour = state.hourlyPrices.first
        return state
    }

    static var previewTodayAndTomorrow: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .current
        let todayStart = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        guard
            let todayTwenty = calendar.date(byAdding: .hour, value: 20, to: todayStart),
            let todayTwentyOne = calendar.date(byAdding: .hour, value: 21, to: todayStart),
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
            let tomorrowZero = calendar.date(byAdding: .hour, value: 0, to: tomorrowStart),
            let tomorrowOne = calendar.date(byAdding: .hour, value: 1, to: tomorrowStart),
            let tomorrowTwo = calendar.date(byAdding: .hour, value: 2, to: tomorrowStart)
        else {
            return previewContent
        }

        let prices = [
            HourlyPrice(classification: .mid, date: todayTwenty, daypart: .night, eurPerKWh: 0.162),
            HourlyPrice(classification: .expensive, date: todayTwentyOne, daypart: .night, eurPerKWh: 0.201),
            HourlyPrice(classification: .cheap, date: tomorrowZero, daypart: .night, eurPerKWh: 0.118),
            HourlyPrice(classification: .mid, date: tomorrowOne, daypart: .night, eurPerKWh: 0.133),
            HourlyPrice(classification: .cheap, date: tomorrowTwo, daypart: .night, eurPerKWh: 0.121),
            HourlyPrice(classification: .mid, date: todayTwenty, daypart: .night, eurPerKWh: 0.162),
            HourlyPrice(classification: .expensive, date: todayTwentyOne, daypart: .night, eurPerKWh: 0.201),
            HourlyPrice(classification: .cheap, date: tomorrowZero, daypart: .night, eurPerKWh: 0.118),
            HourlyPrice(classification: .mid, date: tomorrowOne, daypart: .night, eurPerKWh: 0.133),
            HourlyPrice(classification: .cheap, date: tomorrowTwo, daypart: .night, eurPerKWh: 0.121)
        ]

        return PricesFeature.State(
            costCalculation: CostCalculationFeature.State(),
            hourlyListPresentationMode: .withDateHeaders,
            hourlyPrices: prices,
            isFromCache: false,
            isLoading: false,
            summary: PriceSummary(
                average: 0.181,
                current: prices[0],
                maximum: 0.201,
                maximumHour: prices[1].date,
                minimum: 0.162,
                minimumHour: prices[0].date
            ),
            visibleHourlyPrices: prices
        )
    }
}
