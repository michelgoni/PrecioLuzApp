import ComposableArchitecture
import Foundation

struct OnboardingFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var currentStep: OnboardingStep = .welcome
        var isRequestingNotificationPermission = false
        var notificationPermissionState: NotificationPermissionState = .idle
    }

    @CasePathable
    enum Action: Equatable {
        case backButtonTapped
        case continueButtonTapped
        case finishButtonTapped
        case notificationPermissionButtonTapped
        case notificationPermissionResponse(Bool)
        case swipeBackward
        case swipeForward
    }

    enum NotificationPermissionState: Equatable {
        case denied
        case granted
        case idle
        case requesting
    }

    enum OnboardingStep: Int, CaseIterable, Equatable, Sendable {
        case welcome
        case howItWorks
        case notifications
        case complete

        var accessibilityIdentifier: String {
            switch self {
            case .welcome:
                "onboardingStepWelcome"
            case .howItWorks:
                "onboardingStepHowItWorks"
            case .notifications:
                "onboardingStepNotifications"
            case .complete:
                "onboardingStepComplete"
            }
        }

        var index: Int {
            rawValue + 1
        }

        var isFinal: Bool {
            self == .complete
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                guard let previousStep = state.currentStep.previous else {
                    return .none
                }
                state.currentStep = previousStep
                return .none

            case .continueButtonTapped:
                guard let nextStep = state.currentStep.next else {
                    return .none
                }
                state.currentStep = nextStep
                return .none

            case .finishButtonTapped:
                return .none

            case .notificationPermissionButtonTapped:
                state.isRequestingNotificationPermission = true
                state.notificationPermissionState = .requesting
                return .none

            case let .notificationPermissionResponse(isGranted):
                state.isRequestingNotificationPermission = false
                state.notificationPermissionState = isGranted ? .granted : .denied
                return .none

            case .swipeBackward:
                guard let previousStep = state.currentStep.previous else {
                    return .none
                }
                state.currentStep = previousStep
                return .none

            case .swipeForward:
                guard let nextStep = state.currentStep.next else {
                    return .none
                }
                state.currentStep = nextStep
                return .none
            }
        }
    }
}

extension OnboardingFeature.OnboardingStep {
    var next: Self? {
        Self(rawValue: rawValue + 1)
    }

    var previous: Self? {
        Self(rawValue: rawValue - 1)
    }
}
