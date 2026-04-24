import SwiftUI

struct PricesView: View {
    let onHourTapped: (HourlyPrice) -> Void
    let state: PricesFeature.State

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PricesViewLayout.verticalSpacing) {
                if state.isFromCache {
                    cacheBadge
                }

                if let summary = state.summary {
                    PricesSummaryCardsView(summary: summary)
                } else {
                    noSummaryView
                }

                PricesHourlyListSectionView(
                    currentDate: state.summary?.current?.date,
                    hourlyPrices: state.hourlyPrices,
                    onHourTapped: onHourTapped
                )
                .padding(.top, PricesViewLayout.sectionSpacing)
            }
            .padding(PricesViewLayout.contentPadding)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("pricesScreen")
        .safeAreaPadding(.top, PricesViewLayout.safeAreaTopPadding)
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

}

enum PricesViewLayout {
    static let cardBorderOpacity = 0.15
    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 12
    static let classificationBadgeHorizontalPadding: CGFloat = 8
    static let classificationBadgeVerticalPadding: CGFloat = 4
    static let contentPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 12
    static let hourlyListSpacing: CGFloat = 10
    static let hourlyRowHorizontalPadding: CGFloat = 12
    static let hourlyRowVerticalPadding: CGFloat = 10
    static let iconContainerSize: CGFloat = 28
    static let presetCardBorderWidth: CGFloat = 1
    static let presetCardWidth: CGFloat = 156
    static let safeAreaTopPadding: CGFloat = 8
    static let sectionSpacing: CGFloat = 18
    static let summaryCardSpacing: CGFloat = 6
    static let verticalSpacing: CGFloat = 16
}

enum PricesViewFormatting {
    static func hour(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }

    static func price(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(3)))
    }
}
