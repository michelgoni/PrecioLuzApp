import SwiftUI

struct SettingsThresholdSectionView: View {
    let customThresholdBinding: Binding<Double>
    let customThresholdEnabledBinding: Binding<Bool>
    let customThresholdValue: String
    let notificationsEnabled: Bool
    let thresholdControlEnabled: Bool

    var body: some View {
        Section {
            Toggle(isOn: customThresholdEnabledBinding) {
                SettingsRowLabel(
                    systemImage: "slider.horizontal.3",
                    title: String(localized: "settings.threshold.enabled.title"),
                    iconTint: .orange
                )
            }
            .accessibilityIdentifier("settingsCustomThresholdEnabledToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)

            HStack {
                SettingsRowLabel(
                    systemImage: "eurosign",
                    title: String(localized: "settings.threshold.value.title"),
                    iconTint: .teal
                )
                Spacer()
                Text(customThresholdValue)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settingsThresholdValueLabel")
            }

            Stepper(
                value: customThresholdBinding,
                in: SettingsFeature.State.minimumThresholdEURPerKWh...SettingsFeature.State.maximumThresholdEURPerKWh,
                step: SettingsFeature.State.thresholdStepEURPerKWh
            ) {
                SettingsRowLabel(
                    systemImage: "slider.horizontal.below.square.and.square.filled",
                    title: String(localized: "settings.threshold.stepper.title"),
                    iconTint: .indigo
                )
            }
            .accessibilityIdentifier("settingsThresholdStepper")
            .disabled(!thresholdControlEnabled)
        } header: {
            Text(String(localized: "settings.threshold.section"))
        } footer: {
            Text(String(localized: "settings.threshold.footer"))
        }
    }
}
