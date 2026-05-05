import SwiftUI

struct SettingsDeniedPermissionsSectionView: View {
    @Environment(\.openURL) private var openURL
    let onOpenSystemSettingsTapped: () -> Void

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: SettingsDeniedPermissionsLayout.messageSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: SettingsDeniedPermissionsLayout.iconSize, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: SettingsDeniedPermissionsLayout.iconCircle, height: SettingsDeniedPermissionsLayout.iconCircle)
                    .background(Color.orange.opacity(0.16), in: Circle())
                Text(String(localized: "settings.notifications.permissions.denied.message"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                onOpenSystemSettingsTapped()
                openSystemSettings()
            } label: {
                Label(
                    String(localized: "settings.notifications.permissions.openSettings.button"),
                    systemImage: "gearshape"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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

private enum SettingsDeniedPermissionsLayout {
    static let iconCircle: CGFloat = 24
    static let iconSize: CGFloat = 12
    static let messageSpacing: CGFloat = 8
}
