import SwiftUI

struct SettingsDeniedPermissionsSectionView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Text(String(localized: "settings.notifications.permissions.denied.message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(String(localized: "settings.notifications.permissions.openSettings.button")) {
                openSystemSettings()
            }
            .accessibilityIdentifier("settingsOpenSystemSettingsButton")
        }
    }

    private func openSystemSettings() {
        guard let settingsURL = URL(string: "app-settings:") else {
            return
        }
        openURL(settingsURL)
    }
}
