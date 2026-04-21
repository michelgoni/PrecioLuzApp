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
    private enum Layout {
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 12
        static let contentPadding: CGFloat = 16
        static let gridSpacing: CGFloat = 12
        static let safeAreaTopPadding: CGFloat = 8
        static let summaryCardSpacing: CGFloat = 6
        static let verticalSpacing: CGFloat = 16
    }

    let state: PricesFeature.State

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                if state.isFromCache {
                    cacheBadge
                }

                if let summary = state.summary {
                    summaryGrid(summary)
                } else {
                    noSummaryView
                }
            }
            .padding(Layout.contentPadding)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("pricesScreen")
        .safeAreaPadding(.top, Layout.safeAreaTopPadding)
    }

    private var cacheBadge: some View {
        Label(
            String(localized: "prices.cache.badge"),
            systemImage: "externaldrive.badge.clock"
        )
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("pricesCacheBadge")
    }

    private var noSummaryView: some View {
        Text(String(localized: "prices.summary.empty"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("pricesSummaryEmpty")
    }

    private func summaryGrid(_ summary: PriceSummary) -> some View {
        LazyVGrid(columns: summaryColumns, spacing: Layout.gridSpacing) {
            summaryCard(
                accessibilityIdentifier: "pricesSummaryAverage",
                title: String(localized: "prices.summary.average"),
                value: formattedPrice(summary.average)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryCurrent",
                title: String(localized: "prices.summary.current"),
                value: summary.current.map { formattedPrice($0.eurPerKWh) } ?? placeholderValue
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMaximum",
                title: String(localized: "prices.summary.maximum"),
                value: formattedPrice(summary.maximum)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMinimum",
                title: String(localized: "prices.summary.minimum"),
                value: formattedPrice(summary.minimum)
            )
        }
        .accessibilityIdentifier("pricesSummaryGrid")
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Layout.gridSpacing),
            GridItem(.flexible(), spacing: Layout.gridSpacing),
        ]
    }

    private var placeholderValue: String {
        String(localized: "prices.summary.unavailable")
    }

    private func formattedPrice(_ price: Double) -> String {
        price.formatted(.currency(code: "EUR").precision(.fractionLength(3)))
    }

    private func summaryCard(accessibilityIdentifier: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.summaryCardSpacing) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.cardPadding)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("Prices placeholder") {
    PricesView(
        state: PricesFeature.State()
    )
}

#Preview("Prices summary content") {
    PricesView(
        state: .previewContent
    )
}

#Preview("Prices cached content") {
    PricesView(
        state: .previewCached
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
            hourlyPrices: prices,
            isCalculationPlaceholderPresented: false,
            isFromCache: false,
            selectedHour: nil,
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
}
