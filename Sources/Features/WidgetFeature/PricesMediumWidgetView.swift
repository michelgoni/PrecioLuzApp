import SwiftUI

enum WidgetPriceLevel: Equatable, Sendable {
    case cheap
    case expensive
    case mid
    case neutral
}

struct PricesMediumWidgetPresentationModel: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case content
        case empty
    }

    struct BarEntry: Equatable, Sendable {
        var level: WidgetPriceLevel
        var normalizedHeight: CGFloat
    }

    struct NextHourEntry: Equatable, Sendable, Identifiable {
        var hourText: String
        var id: String { hourText }
        var level: WidgetPriceLevel
        var priceText: String
    }

    var barSeries: [BarEntry]
    var currentPriceText: String
    var currentSlotLabel: String
    var nextHours: [NextHourEntry]
    var state: State
    var timeWindowLabel: String
}

struct PricesMediumWidgetView: View {
    let model: PricesMediumWidgetPresentationModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.widgetCornerRadius, style: .continuous)
                .fill(backgroundGradient)

            if model.state == .content {
                contentLayout
            } else {
                emptyLayout
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Layout.widgetCornerRadius, style: .continuous)
                .stroke(.white.opacity(Layout.borderOpacity), lineWidth: Layout.borderWidth)
        )
        .frame(width: Layout.widgetWidth, height: Layout.widgetHeight)
        .clipShape(RoundedRectangle(cornerRadius: Layout.widgetCornerRadius, style: .continuous))
        .accessibilityIdentifier("pricesMediumWidget")
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.black.opacity(0.96), .black.opacity(0.84)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var contentLayout: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            header

            HStack(alignment: .top, spacing: Layout.contentHorizontalSpacing) {
                currentPriceBlock
                    .frame(width: Layout.leadingColumnWidth, alignment: .leading)
                chartAndNextHoursBlock
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
    }

    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            header

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: Layout.emptyContentSpacing) {
                Text(String(localized: "widget.medium.empty.title"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.titleScaleFactor)

                Text(String(localized: "widget.medium.empty.subtitle"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(Layout.secondaryTextOpacity))
                    .lineLimit(2)
                    .minimumScaleFactor(Layout.subtitleScaleFactor)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
    }

    private var header: some View {
        HStack {
            HStack(spacing: Layout.brandSpacing) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: Layout.brandIconSize, weight: .semibold))
                    .foregroundStyle(.yellow)

                Text(String(localized: "widget.medium.brand"))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(Layout.brandTextOpacity))
                    .tracking(Layout.brandTracking)
            }

            Spacer(minLength: 0)

            Text(model.timeWindowLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(timeWindowTint)
                .padding(.horizontal, Layout.timeWindowHorizontalPadding)
                .padding(.vertical, Layout.timeWindowVerticalPadding)
                .background(timeWindowTint.opacity(Layout.timeWindowBackgroundOpacity))
                .clipShape(Capsule())
                .lineLimit(1)
                .minimumScaleFactor(Layout.badgeScaleFactor)
        }
    }

    private var currentPriceBlock: some View {
        VStack(alignment: .leading, spacing: Layout.currentPriceSpacing) {
            HStack(alignment: .lastTextBaseline, spacing: Layout.currentPriceUnitSpacing) {
                Text(model.currentPriceText)
                    .font(.system(size: Layout.currentPriceFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.priceScaleFactor)

                Text("€")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(Layout.secondaryTextOpacity))
            }

            HStack(spacing: Layout.badgeDotSpacing) {
                Circle()
                    .fill(currentSlotTint)
                    .frame(width: Layout.badgeDotSize, height: Layout.badgeDotSize)
                Text(model.currentSlotLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(Layout.primaryTextOpacity))
            }
            .padding(.horizontal, Layout.slotBadgeHorizontalPadding)
            .padding(.vertical, Layout.slotBadgeVerticalPadding)
            .background(.white.opacity(Layout.slotBadgeBackgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Layout.slotBadgeCornerRadius, style: .continuous))
        }
    }

    private var chartAndNextHoursBlock: some View {
        VStack(alignment: .leading, spacing: Layout.chartVerticalSpacing) {
            HStack(alignment: .bottom, spacing: Layout.barSpacing) {
                ForEach(model.barSeries.indices, id: \.self) { index in
                    let entry = model.barSeries[index]
                    RoundedRectangle(cornerRadius: Layout.barCornerRadius, style: .continuous)
                        .fill(color(for: entry.level).opacity(entry.level == .neutral ? Layout.neutralBarOpacity : 1))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(Layout.minBarHeight, Layout.maxBarHeight * entry.normalizedHeight))
                }
            }
            .frame(height: Layout.maxBarHeight, alignment: .bottom)

            HStack(spacing: Layout.nextHourSpacing) {
                ForEach(model.nextHours.prefix(Layout.maxNextHours)) { hour in
                    VStack(spacing: Layout.nextHourVerticalSpacing) {
                        Text(hour.hourText)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(Layout.tertiaryTextOpacity))
                            .lineLimit(1)
                            .minimumScaleFactor(Layout.badgeScaleFactor)

                        Text(hour.priceText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color(for: hour.level))
                            .lineLimit(1)
                            .minimumScaleFactor(Layout.badgeScaleFactor)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Layout.nextHoursHorizontalPadding)
            .padding(.vertical, Layout.nextHoursVerticalPadding)
            .background(.white.opacity(Layout.nextHoursBackgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Layout.nextHoursCornerRadius, style: .continuous))
        }
    }

    private var currentSlotTint: Color {
        color(for: firstNonNeutralLevel)
    }

    private var firstNonNeutralLevel: WidgetPriceLevel {
        model.barSeries.first { $0.level != .neutral }?.level ?? .mid
    }

    private var timeWindowTint: Color {
        color(for: firstNonNeutralLevel)
    }

    private func color(for level: WidgetPriceLevel) -> Color {
        switch level {
        case .cheap:
            return .green
        case .expensive:
            return .red
        case .mid:
            return .orange
        case .neutral:
            return .white
        }
    }
}

private enum Layout {
    static let badgeDotSize: CGFloat = 6
    static let badgeDotSpacing: CGFloat = 6
    static let badgeScaleFactor = 0.85
    static let barCornerRadius: CGFloat = 2
    static let barSpacing: CGFloat = 3
    static let borderOpacity = 0.12
    static let borderWidth: CGFloat = 1
    static let brandIconSize: CGFloat = 10
    static let brandSpacing: CGFloat = 4
    static let brandTextOpacity = 0.55
    static let brandTracking = 0.4
    static let chartVerticalSpacing: CGFloat = 8
    static let contentHorizontalSpacing: CGFloat = 12
    static let currentPriceFontSize: CGFloat = 30
    static let currentPriceSpacing: CGFloat = 8
    static let currentPriceUnitSpacing: CGFloat = 4
    static let emptyContentSpacing: CGFloat = 4
    static let horizontalPadding: CGFloat = 12
    static let leadingColumnWidth: CGFloat = 100
    static let maxBarHeight: CGFloat = 38
    static let maxNextHours = 3
    static let minBarHeight: CGFloat = 8
    static let neutralBarOpacity = 0.18
    static let nextHoursBackgroundOpacity = 0.06
    static let nextHoursCornerRadius: CGFloat = 10
    static let nextHoursHorizontalPadding: CGFloat = 10
    static let nextHoursVerticalPadding: CGFloat = 6
    static let nextHourSpacing: CGFloat = 8
    static let nextHourVerticalSpacing: CGFloat = 2
    static let primaryTextOpacity = 0.9
    static let priceScaleFactor = 0.75
    static let secondaryTextOpacity = 0.72
    static let slotBadgeBackgroundOpacity = 0.08
    static let slotBadgeCornerRadius: CGFloat = 8
    static let slotBadgeHorizontalPadding: CGFloat = 8
    static let slotBadgeVerticalPadding: CGFloat = 5
    static let subtitleScaleFactor = 0.85
    static let tertiaryTextOpacity = 0.5
    static let timeWindowBackgroundOpacity = 0.16
    static let timeWindowHorizontalPadding: CGFloat = 8
    static let timeWindowVerticalPadding: CGFloat = 4
    static let titleScaleFactor = 0.9
    static let verticalPadding: CGFloat = 12
    static let verticalSpacing: CGFloat = 10
    static let widgetCornerRadius: CGFloat = 28
    static let widgetHeight: CGFloat = 158
    static let widgetWidth: CGFloat = 338
}

#Preview("Medium Widget - content") {
    PricesMediumWidgetView(model: .contentPreview)
        .preferredColorScheme(.dark)
}

#Preview("Medium Widget - empty") {
    PricesMediumWidgetView(model: .emptyPreview)
        .preferredColorScheme(.dark)
}

private extension PricesMediumWidgetPresentationModel {
    static let contentPreview = PricesMediumWidgetPresentationModel(
        barSeries: [
            .init(level: .neutral, normalizedHeight: 0.40),
            .init(level: .neutral, normalizedHeight: 0.30),
            .init(level: .cheap, normalizedHeight: 0.25),
            .init(level: .neutral, normalizedHeight: 0.35),
            .init(level: .neutral, normalizedHeight: 0.50),
            .init(level: .mid, normalizedHeight: 0.65),
            .init(level: .neutral, normalizedHeight: 0.55),
            .init(level: .neutral, normalizedHeight: 0.45),
            .init(level: .expensive, normalizedHeight: 0.80),
            .init(level: .expensive, normalizedHeight: 0.95),
            .init(level: .neutral, normalizedHeight: 0.70),
            .init(level: .neutral, normalizedHeight: 0.60)
        ],
        currentPriceText: "0,142",
        currentSlotLabel: String(localized: "prices.classification.mid"),
        nextHours: [
            .init(hourText: "11:00", level: .cheap, priceText: "0,109"),
            .init(hourText: "12:00", level: .mid, priceText: "0,136"),
            .init(hourText: "13:00", level: .cheap, priceText: "0,098")
        ],
        state: .content,
        timeWindowLabel: "10:00 · \(String(localized: "prices.hourly.current.badge"))"
    )

    static let emptyPreview = PricesMediumWidgetPresentationModel(
        barSeries: [],
        currentPriceText: "—",
        currentSlotLabel: String(localized: "widget.medium.empty.slot"),
        nextHours: [],
        state: .empty,
        timeWindowLabel: String(localized: "widget.medium.empty.timeWindow")
    )
}
