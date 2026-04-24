import SwiftUI

struct PricesCalculationSheetView: View {
    let durationHours: Double
    let durationHoursBinding: Binding<Double>
    let estimatedCostDescription: String
    let onCloseTapped: () -> Void
    let presetBinding: Binding<AppliancePreset.Kind>
    let selectedHour: HourlyPrice?
    let presets: [AppliancePreset]

    var body: some View {
        VStack(alignment: .leading, spacing: PricesViewLayout.verticalSpacing) {
            Text(String(localized: "prices.calculation.placeholder.title"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("pricesCalculationPlaceholderTitle")

            Text(selectedHourDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("pricesCalculationPlaceholderSelectedHour")

            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                Text(String(localized: "prices.calculation.preset.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                PricesSummaryGridView(
                    presetBinding: presetBinding,
                    presets: presets
                )
            }

            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                Text(String(localized: "prices.calculation.duration.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Stepper(
                    value: durationHoursBinding,
                    in: CostCalculationFeature.State.minimumDurationHours...CostCalculationFeature.State.maximumDurationHours,
                    step: CostCalculationFeature.State.stepDurationHours
                ) {
                    Text(durationDescription)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .accessibilityIdentifier("pricesCalculationDurationStepper")
            }

            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                Text(String(localized: "prices.calculation.result.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(estimatedCostDescription)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("pricesCalculationEstimatedCost")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PricesViewLayout.cardPadding)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
            )

            Button(String(localized: "prices.calculation.placeholder.close")) {
                onCloseTapped()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("pricesCalculationPlaceholderCloseButton")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PricesViewLayout.contentPadding)
    }

    private var durationDescription: String {
        String(
            format: String(localized: "prices.calculation.duration.value"),
            durationHours
        )
    }

    private var selectedHourDescription: String {
        guard let selectedHour else {
            return String(localized: "prices.calculation.placeholder.noSelection")
        }
        return String(
            format: String(localized: "prices.calculation.placeholder.selection"),
            PricesViewFormatting.hour(selectedHour.date),
            PricesViewFormatting.price(selectedHour.eurPerKWh)
        )
    }
}

#Preview("Calculation modal selection") {
    PricesCalculationSheetView(
        durationHours: 2.0,
        durationHoursBinding: .constant(2.0),
        estimatedCostDescription: PricesViewFormatting.price(0.58),
        onCloseTapped: {},
        presetBinding: .constant(.washingMachine),
        selectedHour: HourlyPrice(
            classification: .cheap,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            daypart: .morning,
            eurPerKWh: 0.145
        ),
        presets: [
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.airConditioner.name"),
                kind: .airConditioner,
                powerKW: 1.2,
                shortDescription: String(localized: "prices.calculation.preset.airConditioner.description"),
                symbolName: "fan"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.clothesDryer.name"),
                kind: .clothesDryer,
                powerKW: 2.5,
                shortDescription: String(localized: "prices.calculation.preset.clothesDryer.description"),
                symbolName: "wind"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.dishwasher.name"),
                kind: .dishwasher,
                powerKW: 1.5,
                shortDescription: String(localized: "prices.calculation.preset.dishwasher.description"),
                symbolName: "drop"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.electricHeater.name"),
                kind: .electricHeater,
                powerKW: 1.8,
                shortDescription: String(localized: "prices.calculation.preset.electricHeater.description"),
                symbolName: "thermometer.medium"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.electricVehicle.name"),
                kind: .electricVehicle,
                powerKW: 7.2,
                shortDescription: String(localized: "prices.calculation.preset.electricVehicle.description"),
                symbolName: "car"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.inductionCooktop.name"),
                kind: .inductionCooktop,
                powerKW: 1.8,
                shortDescription: String(localized: "prices.calculation.preset.inductionCooktop.description"),
                symbolName: "cooktop"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.oven.name"),
                kind: .oven,
                powerKW: 2.2,
                shortDescription: String(localized: "prices.calculation.preset.oven.description"),
                symbolName: "flame"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.washingMachine.name"),
                kind: .washingMachine,
                powerKW: 2.0,
                shortDescription: String(localized: "prices.calculation.preset.washingMachine.description"),
                symbolName: "washer"
            ),
            AppliancePreset(
                displayName: String(localized: "prices.calculation.preset.waterHeater.name"),
                kind: .waterHeater,
                powerKW: 2.0,
                shortDescription: String(localized: "prices.calculation.preset.waterHeater.description"),
                symbolName: "drop.degreesign"
            ),
        ]
    )
}
