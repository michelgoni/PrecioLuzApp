import SwiftUI

struct PricesHourlyListSectionView: View {
    let currentDate: Date?
    let hourlyPrices: [HourlyPrice]
    let onHourTapped: (HourlyPrice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.hourlyListSpacing) {
            Text(String(localized: "prices.hourly.title"))
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("pricesHourlyTitle")

            if hourlyPrices.isEmpty {
                Text(String(localized: "prices.hourly.empty"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("pricesHourlyEmpty")
            } else {
                hourlyRows
            }
        }
        .accessibilityIdentifier("pricesHourlySection")
    }

    private var hourlyRows: some View {
        VStack(spacing: PricesViewLayout.hourlyListSpacing) {
            ForEach(Array(hourlyPrices.enumerated()), id: \.element.date) { index, hourlyPrice in
                Button {
                    onHourTapped(hourlyPrice)
                } label: {
                    PricesHourlyRowView(
                        hourlyPrice: hourlyPrice,
                        isCurrent: currentDate == hourlyPrice.date
                    )
                    .accessibilityIdentifier("pricesHourlyRow\(index)")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PricesHourlyRowView: View {
    let hourlyPrice: HourlyPrice
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: PricesViewLayout.hourlyListSpacing) {
            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                HStack(spacing: PricesViewLayout.summaryCardSpacing) {
                    Text(PricesViewFormatting.hour(hourlyPrice.date))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)

                    if isCurrent {
                        Text(String(localized: "prices.hourly.current.badge"))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, PricesViewLayout.classificationBadgeHorizontalPadding)
                            .padding(.vertical, PricesViewLayout.classificationBadgeVerticalPadding)
                            .background(Color.accentColor.opacity(PricesViewLayout.cardBorderOpacity), in: Capsule())
                    }
                }

                Text(classificationTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(classificationColor)
                    .padding(.horizontal, PricesViewLayout.classificationBadgeHorizontalPadding)
                    .padding(.vertical, PricesViewLayout.classificationBadgeVerticalPadding)
                    .background(classificationColor.opacity(PricesViewLayout.cardBorderOpacity), in: Capsule())
            }

            Spacer(minLength: 0)

            HStack(spacing: PricesViewLayout.hourlyListSpacing) {
                Text(PricesViewFormatting.price(hourlyPrice.eurPerKWh))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)

                Image(systemName: "plus.forwardslash.minus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: PricesViewLayout.iconContainerSize, height: PricesViewLayout.iconContainerSize)
                    .background(Color(.tertiarySystemFill), in: Circle())
                    .accessibilityIdentifier("pricesHourlyRowCalculator")
            }
        }
        .padding(.horizontal, PricesViewLayout.hourlyRowHorizontalPadding)
        .padding(.vertical, PricesViewLayout.hourlyRowVerticalPadding)
        .background(
            classificationColor.opacity(PricesViewLayout.cardBorderOpacity),
            in: RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
        )
    }

    private var classificationColor: Color {
        switch hourlyPrice.classification {
        case .cheap:
            .green
        case .expensive:
            .red
        case .mid:
            .orange
        }
    }

    private var classificationTitle: String {
        switch hourlyPrice.classification {
        case .cheap:
            String(localized: "prices.classification.cheap")
        case .expensive:
            String(localized: "prices.classification.expensive")
        case .mid:
            String(localized: "prices.classification.mid")
        }
    }
}
