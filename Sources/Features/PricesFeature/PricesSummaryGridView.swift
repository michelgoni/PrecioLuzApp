import SwiftUI

struct PricesSummaryGridView: View {
    let presetBinding: Binding<AppliancePreset.Kind>
    let presets: [AppliancePreset]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: PricesViewLayout.gridSpacing) {
                ForEach(presets, id: \.kind) { preset in
                    presetCard(for: preset)
                }
            }
        }
        .accessibilityIdentifier("pricesCalculationPresetPicker")
    }

    private func presetCard(for preset: AppliancePreset) -> some View {
        let isSelected = preset.kind == presetBinding.wrappedValue
        return Button {
            presetBinding.wrappedValue = preset.kind
        } label: {
            VStack(alignment: .leading, spacing: PricesViewLayout.summaryCardSpacing) {
                HStack(spacing: PricesViewLayout.summaryCardSpacing) {
                    Image(systemName: preset.symbolName)
                        .font(.subheadline.weight(.semibold))
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                }
                Text(preset.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: PricesViewLayout.presetCardWidth, alignment: .leading)
            .padding(PricesViewLayout.cardPadding)
            .background(
                isSelected ? Color.accentColor.opacity(PricesViewLayout.cardBorderOpacity) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: PricesViewLayout.cardCornerRadius)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: PricesViewLayout.presetCardBorderWidth
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pricesPresetCard-\(preset.kind.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("Preset selector horizontal list") {
    @Previewable @State var selectedPreset: AppliancePreset.Kind = .washingMachine

    PricesSummaryGridView(
        presetBinding: $selectedPreset,
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
        ]
    )
    .padding()
}
