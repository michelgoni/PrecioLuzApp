import SwiftUI

struct SettingsAlertsSectionView: View {
    let notifyDailyMaximumBinding: Binding<Bool>
    let notifyDailyMinimumBinding: Binding<Bool>
    let notificationsEnabled: Bool

    var body: some View {
        Section {
            Toggle(isOn: notifyDailyMinimumBinding) {
                SettingsRowLabel(
                    systemImage: "chart.line.downtrend.xyaxis",
                    title: String(localized: "settings.notifications.minimum.title"),
                    iconTint: .green
                )
            }
            .accessibilityIdentifier("settingsNotifyDailyMinimumToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)

            Toggle(isOn: notifyDailyMaximumBinding) {
                SettingsRowLabel(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: String(localized: "settings.notifications.maximum.title"),
                    iconTint: .red
                )
            }
            .accessibilityIdentifier("settingsNotifyDailyMaximumToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)
        } header: {
            Text(String(localized: "settings.notifications.alerts.section"))
        }
    }
}
