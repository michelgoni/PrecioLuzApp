import ComposableArchitecture

struct SettingsFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        static let defaultThresholdEURPerKWh = 0.150
        static let maximumThresholdEURPerKWh = 0.50
        static let minimumThresholdEURPerKWh = 0.05
        static let thresholdStepEURPerKWh = 0.005

        var authorizationStatus: NotificationClient.AuthorizationStatus = .notDetermined
        var notificationSettings = NotificationSettings.productDefaults
    }

    enum Action: Equatable {
        case customThresholdEnabledChanged(Bool)
        case customThresholdEURPerKWhChanged(Double)
        case notificationsEnabledChanged(Bool)
        case notifyDailyMaximumChanged(Bool)
        case notifyDailyMinimumChanged(Bool)
        case openSystemSettingsTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .notificationsEnabledChanged(isEnabled):
                state.notificationSettings.notificationsEnabled = isEnabled
                return .none

            case let .notifyDailyMinimumChanged(isEnabled):
                guard state.notificationSettings.notificationsEnabled else {
                    return .none
                }
                state.notificationSettings.notifyDailyMinimum = isEnabled
                return .none

            case let .notifyDailyMaximumChanged(isEnabled):
                guard state.notificationSettings.notificationsEnabled else {
                    return .none
                }
                state.notificationSettings.notifyDailyMaximum = isEnabled
                return .none

            case let .customThresholdEnabledChanged(isEnabled):
                guard state.notificationSettings.notificationsEnabled else {
                    return .none
                }
                state.notificationSettings.customThresholdEnabled = isEnabled
                return .none

            case let .customThresholdEURPerKWhChanged(value):
                let clampedValue = min(max(value, State.minimumThresholdEURPerKWh), State.maximumThresholdEURPerKWh)
                state.notificationSettings.customThresholdEURPerKWh = roundedThreshold(clampedValue)
                return .none

            case .openSystemSettingsTapped:
                return .none
            }
        }
    }

    private func roundedThreshold(_ value: Double) -> Double {
        let step = State.thresholdStepEURPerKWh
        return (value / step).rounded() * step
    }
}
