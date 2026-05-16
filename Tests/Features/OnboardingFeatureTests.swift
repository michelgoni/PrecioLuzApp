import ComposableArchitecture
import Testing

@testable import PrecioLuzApp

struct OnboardingFeatureTests {
    @MainActor
    @Test("OnboardingFeature advances through all steps")
    func advancesThroughSteps() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.continueButtonTapped) {
            $0.currentStep = .howItWorks
        }
        await store.send(.continueButtonTapped) {
            $0.currentStep = .notifications
        }
        await store.send(.continueButtonTapped) {
            $0.currentStep = .complete
        }
        await store.send(.continueButtonTapped)
    }

    @MainActor
    @Test("OnboardingFeature navigates with swipe actions without finishing")
    func swipeNavigation() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.swipeBackward)
        await store.send(.swipeForward) {
            $0.currentStep = .howItWorks
        }
        await store.send(.swipeForward) {
            $0.currentStep = .notifications
        }
        await store.send(.swipeBackward) {
            $0.currentStep = .howItWorks
        }
        await store.send(.swipeForward) {
            $0.currentStep = .notifications
        }
        await store.send(.swipeForward) {
            $0.currentStep = .complete
        }
        await store.send(.swipeForward)
    }

    @MainActor
    @Test("OnboardingFeature records notification permission result")
    func notificationPermissionResponse() async {
        let store = TestStore(initialState: OnboardingFeature.State(currentStep: .notifications)) {
            OnboardingFeature()
        }

        await store.send(.notificationPermissionButtonTapped) {
            $0.isRequestingNotificationPermission = true
            $0.notificationPermissionState = .requesting
        }
        await store.send(.notificationPermissionResponse(true)) {
            $0.isRequestingNotificationPermission = false
            $0.notificationPermissionState = .granted
        }
    }
}
