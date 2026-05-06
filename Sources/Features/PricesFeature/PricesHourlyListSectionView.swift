import SwiftUI

struct PricesHourlyListSectionView: View {
    struct HourlyPriceSection: Equatable {
        var dayStart: Date
        var hourlyPrices: [HourlyPrice]
    }

    let currentDate: Date?
    let emptyMessage: LocalizedStringResource
    let hourlyListPresentationMode: PricesFeature.State.HourlyListPresentationMode
    let hourlyPrices: [HourlyPrice]
    let onHourTapped: (HourlyPrice) -> Void

    init(
        currentDate: Date?,
        emptyMessage: LocalizedStringResource = "prices.hourly.empty",
        hourlyListPresentationMode: PricesFeature.State.HourlyListPresentationMode,
        hourlyPrices: [HourlyPrice],
        onHourTapped: @escaping (HourlyPrice) -> Void
    ) {
        self.currentDate = currentDate
        self.emptyMessage = emptyMessage
        self.hourlyListPresentationMode = hourlyListPresentationMode
        self.hourlyPrices = hourlyPrices
        self.onHourTapped = onHourTapped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.hourlyListSpacing) {
            sectionTitle

            if hourlyPrices.isEmpty {
                emptyState
            } else {
                if hourlyListPresentationMode == .flatWithAvailabilityNotice {
                    nextDayAvailabilityNotice
                }
                switch hourlyListPresentationMode {
                case .flatWithAvailabilityNotice:
                    hourlyRows(hourlyPrices, rowAccessibilityPrefix: "pricesHourlyRow")
                case .withDateHeaders:
                    sectionedHourlyRows
                }
            }
        }
    }

    private var emptyState: some View {
        Text(emptyMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("pricesHourlyEmpty")
    }

    private func hourlyRows(_ rows: [HourlyPrice], rowAccessibilityPrefix: String) -> some View {
        VStack(spacing: PricesViewLayout.hourlyListSpacing) {
            ForEach(Array(rows.enumerated()), id: \.element.date) { index, hourlyPrice in
                Button {
                    onHourTapped(hourlyPrice)
                } label: {
                    PricesHourlyRowView(
                        hourlyPrice: hourlyPrice,
                        isCurrent: currentDate == hourlyPrice.date
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(rowAccessibilityPrefix)\(index)")
            }
        }
    }

    private var sectionedHourlyRows: some View {
        let sections = makeSections(from: hourlyPrices)
        return VStack(alignment: .leading, spacing: PricesViewLayout.sectionSpacing) {
            ForEach(Array(sections.enumerated()), id: \.element.dayStart) { index, section in
                VStack(alignment: .leading, spacing: PricesViewLayout.hourlyListSpacing) {
                    Text(PricesViewFormatting.dayHeader(section.dayStart))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("pricesHourlyHeader\(index)")

                    hourlyRows(section.hourlyPrices, rowAccessibilityPrefix: "pricesHourlySection\(index)Row")
                }
                .accessibilityIdentifier("pricesHourlySection\(index)")
            }
        }
    }

    private var nextDayAvailabilityNotice: some View {
        Text(String(localized: "prices.hourly.nextDayAvailableAfter2030"))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("pricesHourlyNextDayNotice")
    }

    private func makeSections(from prices: [HourlyPrice]) -> [HourlyPriceSection] {
        let calendar = Calendar(identifier: .gregorian)
        let grouped = Dictionary(grouping: prices) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { HourlyPriceSection(dayStart: $0.key, hourlyPrices: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.dayStart < $1.dayStart }
    }

    private var sectionTitle: some View {
        Text(String(localized: "prices.hourly.title"))
            .font(.headline)
            .foregroundStyle(.primary)
            .accessibilityIdentifier("pricesHourlyTitle")
    }
}

private struct PricesHourlyRowView: View {
    let hourlyPrice: HourlyPrice
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: PricesViewLayout.hourlyListSpacing) {
            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                HStack(spacing: PricesViewLayout.summaryCardSpacing) {
                    hourLabel

                    if isCurrent {
                        currentBadge
                    }
                }

                classificationBadge
            }

            Spacer(minLength: 0)

            HStack(spacing: PricesViewLayout.hourlyListSpacing) {
                priceLabel

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

    private var classificationBadge: some View {
        Text(classificationTitle)
            .font(.caption.weight(.semibold))
            .foregroundStyle(classificationColor)
            .padding(.horizontal, PricesViewLayout.classificationBadgeHorizontalPadding)
            .padding(.vertical, PricesViewLayout.classificationBadgeVerticalPadding)
            .background(classificationColor.opacity(PricesViewLayout.cardBorderOpacity), in: Capsule())
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

    private var currentBadge: some View {
        Text(String(localized: "prices.hourly.current.badge"))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, PricesViewLayout.classificationBadgeHorizontalPadding)
            .padding(.vertical, PricesViewLayout.classificationBadgeVerticalPadding)
            .background(Color.accentColor.opacity(PricesViewLayout.cardBorderOpacity), in: Capsule())
    }

    private var hourLabel: some View {
        Text(PricesViewFormatting.hour(hourlyPrice.date))
            .font(.body.monospacedDigit())
            .foregroundStyle(.primary)
    }

    private var priceLabel: some View {
        Text(PricesViewFormatting.price(hourlyPrice.eurPerKWh))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.primary)
    }
}
