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
        static let cardBorderOpacity = 0.15
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 12
        static let classificationBadgeHorizontalPadding: CGFloat = 8
        static let classificationBadgeVerticalPadding: CGFloat = 4
        static let contentPadding: CGFloat = 16
        static let hourlyListSpacing: CGFloat = 10
        static let hourlyRowHorizontalPadding: CGFloat = 12
        static let hourlyRowVerticalPadding: CGFloat = 10
        static let iconContainerSize: CGFloat = 28
        static let gridSpacing: CGFloat = 12
        static let safeAreaTopPadding: CGFloat = 8
        static let sectionSpacing: CGFloat = 18
        static let summaryCardSpacing: CGFloat = 6
        static let verticalSpacing: CGFloat = 16
    }

    let onCalculationPlaceholderDismissed: () -> Void
    let onHourTapped: (HourlyPrice) -> Void
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

                hourlyListSection
                    .padding(.top, Layout.sectionSpacing)
            }
            .padding(Layout.contentPadding)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("pricesScreen")
        .safeAreaPadding(.top, Layout.safeAreaTopPadding)
        .sheet(
            isPresented: Binding(
                get: { state.isCalculationPlaceholderPresented },
                set: { isPresented in
                    if !isPresented {
                        onCalculationPlaceholderDismissed()
                    }
                }
            )
        ) {
            calculationPlaceholderView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var cacheBadge: some View {
        Label(
            String(localized: "prices.cache.badge", defaultValue: "Datos desde caché"),
            systemImage: "externaldrive.badge.clock"
        )
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("pricesCacheBadge")
    }

    private var noSummaryView: some View {
        Text(String(localized: "prices.summary.empty", defaultValue: "Resumen no disponible"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("pricesSummaryEmpty")
    }

    private var hourlyListSection: some View {
        VStack(alignment: .leading, spacing: Layout.hourlyListSpacing) {
            Text(String(localized: "prices.hourly.title", defaultValue: "Precios por hora"))
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("pricesHourlyTitle")

            if state.hourlyPrices.isEmpty {
                Text(String(localized: "prices.hourly.empty", defaultValue: "No hay precios horarios disponibles"))
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
        VStack(spacing: Layout.hourlyListSpacing) {
            ForEach(Array(state.hourlyPrices.enumerated()), id: \.element.date) { index, hourlyPrice in
                Button {
                    onHourTapped(hourlyPrice)
                } label: {
                    hourlyPriceRow(hourlyPrice: hourlyPrice, isCurrent: isCurrent(hourlyPrice))
                        .accessibilityIdentifier("pricesHourlyRow\(index)")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func hourlyPriceRow(hourlyPrice: HourlyPrice, isCurrent: Bool) -> some View {
        HStack(spacing: Layout.hourlyListSpacing) {
            VStack(alignment: .leading, spacing: Layout.summaryCardSpacing) {
                HStack(spacing: Layout.summaryCardSpacing) {
                    Text(formattedHour(hourlyPrice.date))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)

                    if isCurrent {
                        Text(String(localized: "prices.hourly.current.badge", defaultValue: "Ahora"))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, Layout.classificationBadgeHorizontalPadding)
                            .padding(.vertical, Layout.classificationBadgeVerticalPadding)
                            .background(Color.accentColor.opacity(Layout.cardBorderOpacity), in: Capsule())
                    }
                }

                Text(classificationTitle(hourlyPrice.classification))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(classificationColor(hourlyPrice.classification))
                    .padding(.horizontal, Layout.classificationBadgeHorizontalPadding)
                    .padding(.vertical, Layout.classificationBadgeVerticalPadding)
                    .background(classificationColor(hourlyPrice.classification).opacity(Layout.cardBorderOpacity), in: Capsule())
            }

            Spacer(minLength: 0)

            HStack(spacing: Layout.hourlyListSpacing) {
                Text(formattedPrice(hourlyPrice.eurPerKWh))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)

                Image(systemName: "plus.forwardslash.minus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: Layout.iconContainerSize, height: Layout.iconContainerSize)
                    .background(Color(.tertiarySystemFill), in: Circle())
                    .accessibilityIdentifier("pricesHourlyRowCalculator")
            }
        }
        .padding(.horizontal, Layout.hourlyRowHorizontalPadding)
        .padding(.vertical, Layout.hourlyRowVerticalPadding)
        .background(
            classificationColor(hourlyPrice.classification).opacity(Layout.cardBorderOpacity),
            in: RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
        )
    }

    private func summaryGrid(_ summary: PriceSummary) -> some View {
        LazyVGrid(columns: summaryColumns, spacing: Layout.gridSpacing) {
            summaryCard(
                accessibilityIdentifier: "pricesSummaryAverage",
                title: String(localized: "prices.summary.average", defaultValue: "Media"),
                value: formattedPrice(summary.average)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryCurrent",
                title: String(localized: "prices.summary.current", defaultValue: "Actual"),
                value: summary.current.map { formattedPrice($0.eurPerKWh) } ?? placeholderValue
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMaximum",
                title: String(localized: "prices.summary.maximum", defaultValue: "Máximo"),
                value: formattedPrice(summary.maximum)
            )
            summaryCard(
                accessibilityIdentifier: "pricesSummaryMinimum",
                title: String(localized: "prices.summary.minimum", defaultValue: "Mínimo"),
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
        String(localized: "prices.summary.unavailable", defaultValue: "N/D")
    }

    private func formattedPrice(_ price: Double) -> String {
        price.formatted(.currency(code: "EUR").precision(.fractionLength(3)))
    }

    private func classificationColor(_ classification: PriceClassification) -> Color {
        switch classification {
        case .cheap:
            .green
        case .expensive:
            .red
        case .mid:
            .orange
        }
    }

    private func classificationTitle(_ classification: PriceClassification) -> String {
        switch classification {
        case .cheap:
            String(localized: "prices.classification.cheap", defaultValue: "Barato")
        case .expensive:
            String(localized: "prices.classification.expensive", defaultValue: "Caro")
        case .mid:
            String(localized: "prices.classification.mid", defaultValue: "Medio")
        }
    }

    private func formattedHour(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
    }

    private func isCurrent(_ hourlyPrice: HourlyPrice) -> Bool {
        state.summary?.current?.date == hourlyPrice.date
    }

    private var calculationPlaceholderView: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text(String(localized: "prices.calculation.placeholder.title", defaultValue: "Cálculo de coste"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("pricesCalculationPlaceholderTitle")

            Text(selectedHourDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("pricesCalculationPlaceholderSelectedHour")

            Text(String(localized: "prices.calculation.placeholder.message", defaultValue: "En el siguiente incremento implementaremos presets y duración para calcular el coste."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("pricesCalculationPlaceholderMessage")

            Button(String(localized: "prices.calculation.placeholder.close", defaultValue: "Cerrar")) {
                onCalculationPlaceholderDismissed()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("pricesCalculationPlaceholderCloseButton")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.contentPadding)
    }

    private var selectedHourDescription: String {
        guard let selectedHour = state.selectedHour else {
            return String(localized: "prices.calculation.placeholder.noSelection", defaultValue: "No hay franja seleccionada.")
        }
        let hour = formattedHour(selectedHour.date)
        let price = formattedPrice(selectedHour.eurPerKWh)
        return String(
            format: String(localized: "prices.calculation.placeholder.selection", defaultValue: "Hora %@ · %@"),
            hour,
            price
        )
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
        onCalculationPlaceholderDismissed: {},
        onHourTapped: { _ in },
        state: PricesFeature.State()
    )
}

#Preview("Prices summary content") {
    PricesView(
        onCalculationPlaceholderDismissed: {},
        onHourTapped: { _ in },
        state: .previewContent
    )
}

#Preview("Prices cached content") {
    PricesView(
        onCalculationPlaceholderDismissed: {},
        onHourTapped: { _ in },
        state: .previewCached
    )
}

#Preview("Prices hourly only") {
    var state = PricesFeature.State.previewContent
    state.summary = nil
    return PricesView(
        onCalculationPlaceholderDismissed: {},
        onHourTapped: { _ in },
        state: state
    )
}

#Preview("Prices calculation placeholder") {
    var state = PricesFeature.State.previewContent
    state.isCalculationPlaceholderPresented = true
    state.selectedHour = state.hourlyPrices.first
    return PricesView(
        onCalculationPlaceholderDismissed: {},
        onHourTapped: { _ in },
        state: state
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
