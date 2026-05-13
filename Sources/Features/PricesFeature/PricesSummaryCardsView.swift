import SwiftUI

struct PricesSummaryCardsView: View {
    let entranceTrigger: Bool
    let summary: PriceSummary

    private struct SummaryItem: Identifiable {
        let id: String
        let title: String
        let value: String
        let symbolName: String
        let iconColor: Color
        let iconBackgroundColor: Color
    }

    var body: some View {
        LazyVGrid(columns: summaryColumns, spacing: PricesViewLayout.gridSpacing) {
            ForEach(Array(summaryItems.enumerated()), id: \.element.id) { index, item in
                summaryCard(item: item)
                    .staggeredEntrance(index: index, trigger: entranceTrigger)
            }
        }
        .accessibilityIdentifier("pricesSummaryGrid")
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: PricesViewLayout.gridSpacing),
            GridItem(.flexible(), spacing: PricesViewLayout.gridSpacing),
        ]
    }

    private var summaryItems: [SummaryItem] {
        [
            SummaryItem(
                id: "pricesSummaryAverage",
                title: String(localized: "prices.summary.average"),
                value: PricesViewFormatting.price(summary.average),
                symbolName: "chart.line.uptrend.xyaxis",
                iconColor: .secondary,
                iconBackgroundColor: Color(.tertiarySystemFill)
            ),
            SummaryItem(
                id: "pricesSummaryCurrent",
                title: String(localized: "prices.summary.current"),
                value: summary.current.map { PricesViewFormatting.price($0.eurPerKWh) } ?? String(localized: "prices.summary.unavailable"),
                symbolName: "bolt.fill",
                iconColor: .blue,
                iconBackgroundColor: Color.blue.opacity(0.12)
            ),
            SummaryItem(
                id: "pricesSummaryMaximum",
                title: String(localized: "prices.summary.maximum"),
                value: PricesViewFormatting.price(summary.maximum),
                symbolName: "arrow.up.circle.fill",
                iconColor: .red,
                iconBackgroundColor: Color.red.opacity(0.12)
            ),
            SummaryItem(
                id: "pricesSummaryMinimum",
                title: String(localized: "prices.summary.minimum"),
                value: PricesViewFormatting.price(summary.minimum),
                symbolName: "arrow.down.circle.fill",
                iconColor: .green,
                iconBackgroundColor: Color.green.opacity(0.12)
            ),
        ]
    }

    private func summaryCard(item: SummaryItem) -> some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
            HStack(spacing: PricesViewLayout.summaryCardSpacing) {
                Image(systemName: item.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.iconColor)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(item.iconBackgroundColor)
                    )

                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(item.value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PricesViewLayout.cardPadding)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(item.id)
    }
}
