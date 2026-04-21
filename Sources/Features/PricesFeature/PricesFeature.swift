import ComposableArchitecture
import SwiftUI

struct PricesFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var hourlyPrices: [HourlyPrice] = []
        var isCalculationPlaceholderPresented = false
        var isFromCache = false
        var selectedHour: HourlyPrice?
        var summary: PriceSummary?
    }

    enum Action: Equatable {
        case calculationPlaceholderDismissed
        case hourTapped(HourlyPrice)
        case snapshotLoaded(DailyPricingSnapshotPayload, isCached: Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .calculationPlaceholderDismissed:
                state.isCalculationPlaceholderPresented = false
                return .none

            case let .hourTapped(hour):
                state.selectedHour = hour
                state.isCalculationPlaceholderPresented = true
                return .none

            case let .snapshotLoaded(payload, isCached):
                state.hourlyPrices = payload.hourlyPrices
                state.isFromCache = isCached
                state.selectedHour = payload.hourlyPrices.first { $0.date == state.selectedHour?.date }
                state.summary = payload.summary
                return .none
            }
        }
    }
}

struct PricesView: View {
    let state: PricesFeature.State

    var body: some View {
        Color(.systemBackground)
            .accessibilityIdentifier("pricesScreen")
            .ignoresSafeArea()
    }
}

#Preview("Prices placeholder") {
    PricesView(
        state: PricesFeature.State()
    )
}
