import SwiftUI

struct SettingsAlertsSectionView: View {
    let notifyDailyMaximumBinding: Binding<Bool>
    let notifyDailyMinimumBinding: Binding<Bool>
    let notificationsEnabled: Bool

    var body: some View {
        Section {
            Toggle(
                String(localized: "settings.notifications.minimum.title"),
                isOn: notifyDailyMinimumBinding
            )
            .accessibilityIdentifier("settingsNotifyDailyMinimumToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)

            Toggle(
                String(localized: "settings.notifications.maximum.title"),
                isOn: notifyDailyMaximumBinding
            )
            .accessibilityIdentifier("settingsNotifyDailyMaximumToggle")
            .tint(notificationsEnabled ? .green : .gray)
            .disabled(!notificationsEnabled)
        } header: {
            Text(String(localized: "settings.notifications.alerts.section"))
        }
    }
}
