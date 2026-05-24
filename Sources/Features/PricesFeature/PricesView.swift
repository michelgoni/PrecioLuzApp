import SwiftUI

struct PricesView: View {
    @State private var contentEntranceTriggered = false

    let onHourTapped: (HourlyPrice) -> Void
    let state: PricesFeature.State

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PricesViewLayout.verticalSpacing) {
                if state.isLoading {
                    PricesLoadingSkeletonView()
                        .transition(.opacity)
                } else if state.isFromCache {
                    cacheBadge
                        .transition(.opacity)
                }

                if !state.isLoading {
                    PricesMediumWidgetView(model: mediumWidgetModel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, PricesViewLayout.widgetTopPadding)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("pricesMediumWidgetContainer")
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    if let summary = state.summary {
                        PricesSummaryCardsView(
                            entranceTrigger: contentEntranceTriggered,
                            summary: summary
                        )
                    } else {
                        noSummaryView
                    }

                    PricesHourlyListSectionView(
                        currentDate: state.summary?.current?.date,
                        emptyMessage: state.hourlyPrices.isEmpty
                            ? "prices.hourly.empty"
                            : "prices.hourly.noRemainingToday",
                        entranceTrigger: contentEntranceTriggered,
                        hourlyListPresentationMode: state.hourlyListPresentationMode,
                        hourlyPrices: state.visibleHourlyPrices,
                        onHourTapped: onHourTapped
                    )
                    .padding(.top, PricesViewLayout.sectionSpacing)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(PricesViewLayout.contentPadding)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("pricesScreen")
        .animation(MotionTokens.standard, value: state.isLoading)
        .onAppear {
            if !state.isLoading {
                contentEntranceTriggered = true
            }
        }
        .onChange(of: state.isLoading) { _, isLoading in
            if isLoading {
                contentEntranceTriggered = false
            } else {
                contentEntranceTriggered = true
            }
        }
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

    private var mediumWidgetModel: PricesMediumWidgetPresentationModel {
        PricesMediumWidgetMapper.makeModel(
            from: state.hourlyPrices,
            now: state.summary?.current?.date ?? Date(),
            calendar: .current
        )
    }
}

private struct PricesLoadingSkeletonView: View {
    private let placeholderRows = 8

    var body: some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.sectionSpacing) {
            RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
                .fill(Color(.systemGray5))
                .frame(height: PricesViewLayout.skeletonBadgeHeight)
                .shimmer()

            VStack(spacing: PricesViewLayout.gridSpacing) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: PricesViewLayout.gridSpacing) {
                        skeletonCard
                        skeletonCard
                    }
                }
            }

            VStack(spacing: PricesViewLayout.hourlyListSpacing) {
                ForEach(0..<placeholderRows, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
                        .fill(Color(.systemGray5))
                        .frame(height: PricesViewLayout.skeletonRowHeight)
                        .shimmer()
                }
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityIdentifier("pricesLoadingSkeleton")
    }

    private var skeletonCard: some View {
        RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: PricesViewLayout.skeletonCardHeight)
            .shimmer()
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
    static let skeletonBadgeHeight: CGFloat = 24
    static let skeletonCardHeight: CGFloat = 74
    static let skeletonRowHeight: CGFloat = 52
    static let summaryCardSpacing: CGFloat = 6
    static let verticalSpacing: CGFloat = 16
    static let widgetTopPadding: CGFloat = 2
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

    static func dayHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }
}
