import SwiftUI

struct SettingsNotificationsSectionView: View {
    let notificationsEnabledBinding: Binding<Bool>

    var body: some View {
        Section {
            Toggle(
                String(localized: "settings.notifications.enabled.title"),
                isOn: notificationsEnabledBinding
            )
            .accessibilityIdentifier("settingsNotificationsEnabledToggle")
            .tint(.green)
        } footer: {
            Text(String(localized: "settings.notifications.enabled.footer"))
        }
    }
}
