import SwiftUI

struct SettingsNotificationsSectionView: View {
    let notificationsEnabledBinding: Binding<Bool>

    var body: some View {
        Section {
            Toggle(isOn: notificationsEnabledBinding) {
                SettingsRowLabel(
                    systemImage: "bell.ring.fill",
                    title: String(localized: "settings.notifications.enabled.title"),
                    iconTint: .blue
                )
            }
            .accessibilityIdentifier("settingsNotificationsEnabledToggle")
            .tint(.green)
        } footer: {
            Text(String(localized: "settings.notifications.enabled.footer"))
        }
    }
}
