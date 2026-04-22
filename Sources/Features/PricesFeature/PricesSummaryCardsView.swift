import SwiftUI

struct PricesSummaryCardsView: View {
    let summary: PriceSummary

    var body: some View {
        LazyVGrid(columns: summaryColumns, spacing: PricesViewLayout.gridSpacing) {
            summaryCard(
                accessibilityIdentifier: "pricesSummaryAverage",
                title: String(localized: "prices.summary.average"),
                value: PricesViewFormatting.price(summary.average)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryCurrent",
                title: String(localized: "prices.summary.current"),
                value: summary.current.map { PricesViewFormatting.price($0.eurPerKWh) } ?? String(localized: "prices.summary.unavailable")
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMaximum",
                title: String(localized: "prices.summary.maximum"),
                value: PricesViewFormatting.price(summary.maximum)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMinimum",
                title: String(localized: "prices.summary.minimum"),
                value: PricesViewFormatting.price(summary.minimum)
            )
        }
        .accessibilityIdentifier("pricesSummaryGrid")
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: PricesViewLayout.gridSpacing),
            GridItem(.flexible(), spacing: PricesViewLayout.gridSpacing),
        ]
    }

    private func summaryCard(accessibilityIdentifier: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PricesViewLayout.cardPadding)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
