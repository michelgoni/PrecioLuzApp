import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    var body: some View {
        List {
            SettingsNotificationsSectionView(
                notificationsEnabledBinding: notificationsEnabledBinding
            )

            if store.authorizationStatus == .denied {
                SettingsDeniedPermissionsSectionView()
            }

            SettingsAlertsSectionView(
                notifyDailyMaximumBinding: notifyDailyMaximumBinding,
                notifyDailyMinimumBinding: notifyDailyMinimumBinding,
                notificationsEnabled: store.notificationSettings.notificationsEnabled
            )

            SettingsThresholdSectionView(
                customThresholdBinding: customThresholdBinding,
                customThresholdEnabledBinding: customThresholdEnabledBinding,
                customThresholdValue: customThresholdValue,
                notificationsEnabled: store.notificationSettings.notificationsEnabled,
                thresholdControlEnabled: isThresholdControlEnabled
            )
        }
        .accessibilityIdentifier("settingsScreen")
        .navigationTitle(String(localized: "tab.settings.title"))
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.notificationSettings.notificationsEnabled },
            set: { store.send(.notificationsEnabledChanged($0)) }
        )
    }

    private var notifyDailyMinimumBinding: Binding<Bool> {
        Binding(
            get: { store.notificationSettings.notifyDailyMinimum },
            set: { store.send(.notifyDailyMinimumChanged($0)) }
        )
    }

    private var notifyDailyMaximumBinding: Binding<Bool> {
        Binding(
            get: { store.notificationSettings.notifyDailyMaximum },
            set: { store.send(.notifyDailyMaximumChanged($0)) }
        )
    }

    private var customThresholdEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.notificationSettings.customThresholdEnabled },
            set: { store.send(.customThresholdEnabledChanged($0)) }
        )
    }

    private var customThresholdBinding: Binding<Double> {
        Binding(
            get: {
                store.notificationSettings.customThresholdEURPerKWh ?? SettingsFeature.State.defaultThresholdEURPerKWh
            },
            set: { store.send(.customThresholdEURPerKWhChanged($0)) }
        )
    }

    private var customThresholdValue: String {
        let threshold = store.notificationSettings.customThresholdEURPerKWh ?? SettingsFeature.State.defaultThresholdEURPerKWh
        return PricesViewFormatting.price(threshold)
    }

    private var isThresholdControlEnabled: Bool {
        store.notificationSettings.notificationsEnabled && store.notificationSettings.customThresholdEnabled
    }
}
