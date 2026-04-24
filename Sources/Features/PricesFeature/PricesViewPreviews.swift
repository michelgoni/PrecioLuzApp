import Foundation
import SwiftUI

#Preview("Prices placeholder") {
    PricesView(
        onCalculationDurationHoursChanged: { _ in },
        onCalculationPlaceholderDismissed: {},
        onCalculationPresetSelected: { _ in },
        onHourTapped: { _ in },
        state: PricesFeature.State()
    )
}

#Preview("Prices summary content") {
    PricesView(
        onCalculationDurationHoursChanged: { _ in },
        onCalculationPlaceholderDismissed: {},
        onCalculationPresetSelected: { _ in },
        onHourTapped: { _ in },
        state: .previewContent
    )
}

#Preview("Prices cached content") {
    PricesView(
        onCalculationDurationHoursChanged: { _ in },
        onCalculationPlaceholderDismissed: {},
        onCalculationPresetSelected: { _ in },
        onHourTapped: { _ in },
        state: .previewCached
    )
}

#Preview("Prices hourly only") {
    PricesView(
        onCalculationDurationHoursChanged: { _ in },
        onCalculationPlaceholderDismissed: {},
        onCalculationPresetSelected: { _ in },
        onHourTapped: { _ in },
        state: .previewHourlyOnly
    )
}

#Preview("Prices calculation placeholder") {
    PricesView(
        onCalculationDurationHoursChanged: { _ in },
        onCalculationPlaceholderDismissed: {},
        onCalculationPresetSelected: { _ in },
        onHourTapped: { _ in },
        state: .previewCalculationSheet
    )
}

private extension PricesFeature.State {
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
            ),
        ]
        return PricesFeature.State(
            costCalculation: CostCalculationFeature.State(),
            hourlyPrices: prices,
            isFromCache: false,
            summary: PriceSummary(
                average: 0.158,
                current: prices[1],
                maximum: 0.215,
                maximumHour: prices[2].date,
                minimum: 0.10,
                minimumHour: prices[0].date
            )
        )
    }

    static var previewHourlyOnly: Self {
        var state = previewContent
        state.summary = nil
        return state
    }

    static var previewCalculationSheet: Self {
        var state = previewContent
        state.costCalculation.isPresented = true
        state.costCalculation.selectedHour = state.hourlyPrices.first
        return state
    }
}
