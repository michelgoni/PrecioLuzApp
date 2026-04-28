import SwiftUI

struct SettingsThresholdSectionView: View {
    let customThresholdBinding: Binding<Double>
    let customThresholdEnabledBinding: Binding<Bool>
    let customThresholdValue: String
    let notificationsEnabled: Bool
    let thresholdControlEnabled: Bool

    var body: some View {
        Section {
            Toggle(
                String(localized: "settings.threshold.enabled.title"),
                isOn: customThresholdEnabledBinding
            )
            .accessibilityIdentifier("settingsCustomThresholdEnabledToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)

            HStack {
                Text(String(localized: "settings.threshold.value.title"))
                Spacer()
                Text(customThresholdValue)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settingsThresholdValueLabel")
            }

            Stepper(
                String(localized: "settings.threshold.stepper.title"),
                value: customThresholdBinding,
                in: SettingsFeature.State.minimumThresholdEURPerKWh...SettingsFeature.State.maximumThresholdEURPerKWh,
                step: SettingsFeature.State.thresholdStepEURPerKWh
            )
            .accessibilityIdentifier("settingsThresholdStepper")
            .disabled(!thresholdControlEnabled)
        } header: {
            Text(String(localized: "settings.threshold.section"))
        } footer: {
            Text(String(localized: "settings.threshold.footer"))
        }
    }
}
