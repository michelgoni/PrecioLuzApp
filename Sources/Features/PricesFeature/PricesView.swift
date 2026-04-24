import SwiftUI

struct PricesView: View {
    let onCalculationDurationHoursChanged: (Double) -> Void
    let onCalculationPlaceholderDismissed: () -> Void
    let onCalculationPresetSelected: (AppliancePreset.Kind) -> Void
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
        .sheet(isPresented: isCalculationSheetPresentedBinding) {
            PricesCalculationSheetView(
                durationHours: state.costCalculation.durationHours,
                durationHoursBinding: calculationDurationBinding,
                onCloseTapped: onCalculationPlaceholderDismissed,
                presetBinding: selectedPresetBinding,
                selectedHour: state.costCalculation.selectedHour,
                selectedPreset: PricesPresetCatalog.preset(for: state.costCalculation.selectedPresetKind),
                presets: PricesPresetCatalog.all
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
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

    private var calculationDurationBinding: Binding<Double> {
        Binding(
            get: { state.costCalculation.durationHours },
            set: { onCalculationDurationHoursChanged($0) }
        )
    }

    private var isCalculationSheetPresentedBinding: Binding<Bool> {
        Binding(
            get: { state.costCalculation.isPresented },
            set: { isPresented in
                if !isPresented {
                    onCalculationPlaceholderDismissed()
                }
            }
        )
    }

    private var noSummaryView: some View {
        Text(String(localized: "prices.summary.empty"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("pricesSummaryEmpty")
    }

    private var selectedPresetBinding: Binding<AppliancePreset.Kind> {
        Binding(
            get: { state.costCalculation.selectedPresetKind },
            set: { onCalculationPresetSelected($0) }
        )
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

private enum PricesPresetCatalog {
    private static let airConditionerPowerKW = 1.2
    private static let clothesDryerPowerKW = 2.5
    private static let dishwasherPowerKW = 1.5
    private static let electricHeaterPowerKW = 1.8
    private static let electricVehiclePowerKW = 7.2
    private static let inductionCooktopPowerKW = 1.8
    private static let ovenPowerKW = 2.2
    private static let washingMachinePowerKW = 2.0
    private static let waterHeaterPowerKW = 2.0

    static var all: [AppliancePreset] {
        [
            preset(
                shortDescription: String(localized: "prices.calculation.preset.airConditioner.description"),
                kind: .airConditioner,
                displayName: String(localized: "prices.calculation.preset.airConditioner.name"),
                powerKW: airConditionerPowerKW,
                symbolName: "fan"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.clothesDryer.description"),
                kind: .clothesDryer,
                displayName: String(localized: "prices.calculation.preset.clothesDryer.name"),
                powerKW: clothesDryerPowerKW,
                symbolName: "wind"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.dishwasher.description"),
                kind: .dishwasher,
                displayName: String(localized: "prices.calculation.preset.dishwasher.name"),
                powerKW: dishwasherPowerKW,
                symbolName: "drop"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.electricHeater.description"),
                kind: .electricHeater,
                displayName: String(localized: "prices.calculation.preset.electricHeater.name"),
                powerKW: electricHeaterPowerKW,
                symbolName: "thermometer.medium"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.electricVehicle.description"),
                kind: .electricVehicle,
                displayName: String(localized: "prices.calculation.preset.electricVehicle.name"),
                powerKW: electricVehiclePowerKW,
                symbolName: "car"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.inductionCooktop.description"),
                kind: .inductionCooktop,
                displayName: String(localized: "prices.calculation.preset.inductionCooktop.name"),
                powerKW: inductionCooktopPowerKW,
                symbolName: "cooktop"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.oven.description"),
                kind: .oven,
                displayName: String(localized: "prices.calculation.preset.oven.name"),
                powerKW: ovenPowerKW,
                symbolName: "flame"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.washingMachine.description"),
                kind: .washingMachine,
                displayName: String(localized: "prices.calculation.preset.washingMachine.name"),
                powerKW: washingMachinePowerKW,
                symbolName: "washer"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.waterHeater.description"),
                kind: .waterHeater,
                displayName: String(localized: "prices.calculation.preset.waterHeater.name"),
                powerKW: waterHeaterPowerKW,
                symbolName: "drop.degreesign"
            ),
        ]
    }

    static func preset(for kind: AppliancePreset.Kind) -> AppliancePreset {
        all.first(where: { $0.kind == kind }) ?? fallbackPreset
    }

    private static var fallbackPreset: AppliancePreset {
        preset(
            shortDescription: String(localized: "prices.calculation.preset.washingMachine.description"),
            kind: .washingMachine,
            displayName: String(localized: "prices.calculation.preset.washingMachine.name"),
            powerKW: washingMachinePowerKW,
            symbolName: "washer"
        )
    }

    private static func preset(
        shortDescription: String,
        kind: AppliancePreset.Kind,
        displayName: String,
        powerKW: Double,
        symbolName: String
    ) -> AppliancePreset {
        AppliancePreset(
            displayName: displayName,
            kind: kind,
            powerKW: powerKW,
            shortDescription: shortDescription,
            symbolName: symbolName
        )
    }
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
