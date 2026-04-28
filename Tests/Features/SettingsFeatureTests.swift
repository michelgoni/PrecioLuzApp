import ComposableArchitecture
import Testing

@testable import PrecioLuzApp

@MainActor
struct SettingsFeatureTests {
    @Test("SettingsFeature starts with product default values")
    func defaultStateMatchesProductDefaults() async {
        let state = SettingsFeature.State()

        #expect(state.notificationSettings.notificationsEnabled == false)
        #expect(state.notificationSettings.notifyDailyMinimum == true)
        #expect(state.notificationSettings.notifyDailyMaximum == false)
        #expect(state.notificationSettings.customThresholdEnabled == false)
        #expect(state.notificationSettings.customThresholdEURPerKWh == 0.150)
    }

    @Test("SettingsFeature ignores dependent toggles while global notifications are disabled")
    func dependentTogglesIgnoredWhenNotificationsDisabled() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.notifyDailyMinimumChanged(false))
        await store.send(.notifyDailyMaximumChanged(true))
        await store.send(.customThresholdEnabledChanged(true))

        #expect(store.state.notificationSettings.notifyDailyMinimum == true)
        #expect(store.state.notificationSettings.notifyDailyMaximum == false)
        #expect(store.state.notificationSettings.customThresholdEnabled == false)
    }

    @Test("SettingsFeature enables dependent toggles when global notifications are enabled")
    func dependentTogglesUpdateWhenNotificationsEnabled() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.notificationsEnabledChanged(true)) {
            $0.notificationSettings.notificationsEnabled = true
        }
        await store.send(.notifyDailyMinimumChanged(false)) {
            $0.notificationSettings.notifyDailyMinimum = false
        }
        await store.send(.notifyDailyMaximumChanged(true)) {
            $0.notificationSettings.notifyDailyMaximum = true
        }
        await store.send(.customThresholdEnabledChanged(true)) {
            $0.notificationSettings.customThresholdEnabled = true
        }
    }

    @Test("SettingsFeature clamps threshold value inside supported range")
    func thresholdClampsToSupportedRange() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.customThresholdEURPerKWhChanged(0.01)) {
            $0.notificationSettings.customThresholdEURPerKWh = 0.05
        }
        await store.send(.customThresholdEURPerKWhChanged(0.80)) {
            $0.notificationSettings.customThresholdEURPerKWh = 0.50
        }
    }

    @Test("SettingsFeature rounds threshold to step of 0.005")
    func thresholdRoundsToExpectedStep() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.customThresholdEURPerKWhChanged(0.153)) {
            $0.notificationSettings.customThresholdEURPerKWh = 0.155
        }
    }
}
