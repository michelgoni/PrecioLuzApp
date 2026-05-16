import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var transitionDirection: OnboardingTransitionDirection = .forward
    let store: StoreOf<OnboardingFeature>

    var body: some View {
        let palette = OnboardingPalette(colorScheme: colorScheme)
        ZStack {
            OnboardingBackgroundView(palette: palette)
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(store.currentStep.accessibilityIdentifier)
            VStack(spacing: 0) {
                header(palette: palette)
                stepContent(palette: palette)
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .contentShape(Rectangle())
            .simultaneousGesture(horizontalSwipeGesture)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Button {
                transitionDirection = .forward
                let action: OnboardingFeature.Action = store.currentStep.isFinal ? .finishButtonTapped : .continueButtonTapped
                store.send(action, animation: reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.86))
            } label: {
                HStack(spacing: 8) {
                    Text(primaryButtonTitle)
                    if !store.currentStep.isFinal {
                        Image(systemName: "arrow.right")
                            .font(.footnote.weight(.bold))
                    }
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .accessibilityIdentifier("onboardingPrimaryButton")
        }
    }

    private func header(palette: OnboardingPalette) -> some View {
        HStack(spacing: 12) {
            OnboardingProgressView(currentStep: store.currentStep, palette: palette)
            Spacer(minLength: 12)
            Text(
                String(
                    format: String(localized: "onboarding.progress.format"),
                    store.currentStep.index,
                    OnboardingFeature.OnboardingStep.allCases.count
                )
            )
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.secondaryText)
                .accessibilityIdentifier("onboardingProgressLabel")
        }
        .padding(.top, 30)
    }

    @ViewBuilder
    private func stepContent(palette: OnboardingPalette) -> some View {
        Group {
            switch store.currentStep {
            case .welcome:
                OnboardingWelcomeStepView(palette: palette)
            case .howItWorks:
                OnboardingHowItWorksStepView(palette: palette)
            case .notifications:
                OnboardingNotificationsStepView(
                    isRequestingPermission: store.isRequestingNotificationPermission,
                    permissionState: store.notificationPermissionState,
                    onPermissionTapped: { store.send(.notificationPermissionButtonTapped) },
                    palette: palette
                )
            case .complete:
                OnboardingCompleteStepView(palette: palette)
            }
        }
        .id(store.currentStep)
        .transition(stepTransition)
        .animation(reduceMotion ? nil : .spring(response: 0.44, dampingFraction: 0.86), value: store.currentStep)
    }

    private var primaryButtonTitle: String {
        switch store.currentStep {
        case .complete:
            String(localized: "onboarding.complete.primaryButton")
        default:
            String(localized: "onboarding.continue")
        }
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .asymmetric(
                insertion: .opacity.combined(with: .move(edge: transitionDirection.insertionEdge)),
                removal: .opacity.combined(with: .move(edge: transitionDirection.removalEdge))
            )
        }
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = value.translation.height
                guard abs(horizontalDistance) > abs(verticalDistance) else { return }
                guard abs(horizontalDistance) >= 64 else { return }

                if horizontalDistance < 0 {
                    transitionDirection = .forward
                    store.send(.swipeForward, animation: reduceMotion ? nil : .spring(response: 0.40, dampingFraction: 0.86))
                } else {
                    transitionDirection = .backward
                    store.send(.swipeBackward, animation: reduceMotion ? nil : .spring(response: 0.40, dampingFraction: 0.86))
                }
            }
    }
}

private struct OnboardingPalette {
    let colorScheme: ColorScheme

    var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.62) : .black.opacity(0.65)
    }

    var surface: Color {
        colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.92)
    }

    var elevatedSurface: Color {
        colorScheme == .dark ? .white.opacity(0.045) : .white.opacity(0.96)
    }

    var stroke: Color {
        colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.10)
    }

    var deepSurface: Color {
        colorScheme == .dark ? .black.opacity(0.24) : .black.opacity(0.07)
    }

    var background: Color {
        colorScheme == .dark ? Color(red: 0.03, green: 0.04, blue: 0.07) : Color(red: 0.96, green: 0.98, blue: 1.0)
    }

    var accentBlue: Color { .blue }
    var accentGreen: Color { .green }
}

private enum OnboardingTransitionDirection {
    case backward
    case forward

    var insertionEdge: Edge {
        switch self {
        case .backward:
            .leading
        case .forward:
            .trailing
        }
    }

    var removalEdge: Edge {
        switch self {
        case .backward:
            .trailing
        case .forward:
            .leading
        }
    }
}

private struct OnboardingBackgroundView: View {
    let palette: OnboardingPalette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            Circle()
                .fill(Color.blue.opacity(palette.colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 120, y: -280)
            Circle()
                .fill(Color.green.opacity(palette.colorScheme == .dark ? 0.10 : 0.09))
                .frame(width: 220, height: 220)
                .blur(radius: 58)
                .offset(x: -140, y: 170)
            Circle()
                .fill((palette.colorScheme == .dark ? Color.white : Color.black).opacity(0.06))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 120, y: 300)
        }
    }
}

private struct OnboardingBenefitTile: View {
    let palette: OnboardingPalette
    let color: Color
    let symbolName: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

private struct OnboardingCompleteStepView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    let palette: OnboardingPalette

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(palette.elevatedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(palette.stroke, lineWidth: 1)
                        )
                    Circle()
                        .stroke(Color.green.opacity(palette.colorScheme == .dark ? 0.34 : 0.45), lineWidth: 1)
                        .frame(width: isAnimating && !reduceMotion ? 158 : 138, height: isAnimating && !reduceMotion ? 158 : 138)
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 112, height: 112)
                        .overlay {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 54, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "checkmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.green))
                                .overlay(Circle().stroke(palette.background, lineWidth: 4))
                                .offset(x: 10, y: 10)
                        }
                }
                .frame(height: 250)
                .shadow(color: .green.opacity(0.22), radius: 30, x: 0, y: 16)

                VStack(spacing: 14) {
                    Label(String(localized: "onboarding.complete.badge"), systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                    Text(String(localized: "onboarding.complete.title"))
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding.complete.subtitle"))
                        .font(.body)
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    OnboardingBenefitTile(palette: palette, color: .blue, symbolName: "clock", title: String(localized: "onboarding.complete.benefit.hours"))
                    OnboardingBenefitTile(palette: palette, color: .green, symbolName: "bell.badge", title: String(localized: "onboarding.complete.benefit.alerts"))
                    OnboardingBenefitTile(
                        palette: palette,
                        color: palette.colorScheme == .dark ? .white.opacity(0.82) : .black.opacity(0.70),
                        symbolName: "function",
                        title: String(localized: "onboarding.complete.benefit.calculation")
                    )
                }
            }
            .padding(.top, 38)
            .padding(.bottom, 24)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct OnboardingFeatureCard: View {
    let palette: OnboardingPalette
    let color: Color
    let symbolName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(Circle().stroke(palette.stroke, lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(palette.colorScheme == .dark ? 0.28 : 0.10), radius: 18, x: 0, y: 10)
    }
}

private struct OnboardingHowItWorksStepView: View {
    let palette: OnboardingPalette

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "bolt.fill")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.blue)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(palette.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(palette.stroke, lineWidth: 1)
                        )
                    Text(String(localized: "onboarding.howItWorks.eyebrow"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                    Text(String(localized: "onboarding.howItWorks.title"))
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-0.8)
                        .lineSpacing(-2)
                    Text(String(localized: "onboarding.howItWorks.subtitle"))
                        .font(.body)
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                }

                VStack(spacing: 12) {
                    OnboardingFeatureCard(
                        palette: palette,
                        color: .blue,
                        symbolName: "clock",
                        title: String(localized: "onboarding.howItWorks.hourly.title"),
                        subtitle: String(localized: "onboarding.howItWorks.hourly.subtitle")
                    )
                    OnboardingFeatureCard(
                        palette: palette,
                        color: palette.colorScheme == .dark ? .white.opacity(0.86) : .black.opacity(0.75),
                        symbolName: "function",
                        title: String(localized: "onboarding.howItWorks.calculation.title"),
                        subtitle: String(localized: "onboarding.howItWorks.calculation.subtitle")
                    )
                    OnboardingFeatureCard(
                        palette: palette,
                        color: .orange,
                        symbolName: "bell",
                        title: String(localized: "onboarding.howItWorks.alerts.title"),
                        subtitle: String(localized: "onboarding.howItWorks.alerts.subtitle")
                    )
                }
            }
            .padding(.top, 38)
            .padding(.bottom, 24)
        }
    }
}

private struct OnboardingNotificationsStepView: View {
    let isRequestingPermission: Bool
    let permissionState: OnboardingFeature.NotificationPermissionState
    let onPermissionTapped: () -> Void
    let palette: OnboardingPalette

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill((palette.colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                        .frame(width: 228, height: 228)
                        .overlay(Circle().stroke(palette.stroke, lineWidth: 1))
                    Circle()
                        .fill(Color(.secondarySystemBackground).opacity(0.82))
                        .frame(width: 160, height: 160)
                    notificationChip(String(localized: "onboarding.notifications.minimum"), color: .green)
                        .offset(x: -74, y: -62)
                    notificationChip(String(localized: "onboarding.notifications.expensive"), color: .red)
                        .offset(x: 70, y: 70)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                        .frame(width: 112, height: 112)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(palette.surface)
                        )
                        .overlay(alignment: .topTrailing) {
                            Text("2")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(.blue))
                                .offset(x: 4, y: -4)
                        }
                }
                .frame(height: 250)

                VStack(spacing: 14) {
                    Text(String(localized: "onboarding.notifications.title"))
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding.notifications.subtitle"))
                        .font(.body)
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: permissionIconName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.blue.opacity(0.16)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(localized: "onboarding.notifications.card.title"))
                                .font(.subheadline.weight(.semibold))
                            Text(permissionDescription)
                                .font(.caption)
                                .foregroundStyle(palette.secondaryText)
                        }
                        Spacer(minLength: 0)
                        Button(action: onPermissionTapped) {
                            Group {
                                if isRequestingPermission {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: permissionButtonIconName)
                                        .font(.headline.weight(.bold))
                                }
                            }
                            .frame(width: 58, height: 38)
                        }
                        .buttonStyle(.plain)
                        .background(Capsule().fill(permissionButtonColor))
                        .accessibilityIdentifier("onboardingNotificationsPermissionButton")
                        .accessibilityLabel(permissionButtonAccessibilityLabel)
                        .disabled(isRequestingPermission || permissionState == .granted)
                    }

                    VStack(spacing: 8) {
                        permissionBenefit(String(localized: "onboarding.notifications.benefit.minimum"))
                        permissionBenefit(String(localized: "onboarding.notifications.benefit.expensive"))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
            .padding(.top, 38)
            .padding(.bottom, 24)
        }
    }

    private var permissionButtonAccessibilityLabel: String {
        switch permissionState {
        case .granted:
            String(localized: "onboarding.notifications.permission.granted")
        default:
            String(localized: "onboarding.notifications.permission.request")
        }
    }

    private var permissionButtonColor: Color {
        switch permissionState {
        case .denied:
            .red.opacity(0.72)
        case .granted:
            .green
        case .idle, .requesting:
            .blue
        }
    }

    private var permissionButtonIconName: String {
        switch permissionState {
        case .denied:
            "xmark"
        case .granted:
            "checkmark"
        case .idle, .requesting:
            "bell"
        }
    }

    private var permissionDescription: String {
        switch permissionState {
        case .denied:
            String(localized: "onboarding.notifications.permission.denied")
        case .granted:
            String(localized: "onboarding.notifications.permission.granted")
        case .idle, .requesting:
            String(localized: "onboarding.notifications.card.subtitle")
        }
    }

    private var permissionIconName: String {
        switch permissionState {
        case .granted:
            "bell.badge.fill"
        default:
            "bell"
        }
    }

    private func notificationChip(_ text: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func permissionBenefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.deepSurface)
        )
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(colorScheme == .dark ? Color.white : Color.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.blue)
            )
            .shadow(color: .blue.opacity(0.28), radius: 18, x: 0, y: 12)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct OnboardingProgressView: View {
    let currentStep: OnboardingFeature.OnboardingStep
    let palette: OnboardingPalette

    var body: some View {
        HStack(spacing: 7) {
            ForEach(OnboardingFeature.OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.blue : palette.stroke)
                    .frame(width: step == currentStep ? 28 : 10, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingWelcomeStepView: View {
    let palette: OnboardingPalette

    var body: some View {
        VStack(spacing: 34) {
            Spacer(minLength: 20)
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.16))
                    .frame(width: 184, height: 184)
                    .blur(radius: 8)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(.blue)
                    .shadow(color: .blue.opacity(0.38), radius: 26, x: 0, y: 18)
            }
            Spacer(minLength: 12)
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.welcome.title"))
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "onboarding.welcome.subtitle"))
                    .font(.title3)
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 20)
        }
    }
}

#Preview("Onboarding - welcome") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(currentStep: .welcome)) {
            OnboardingFeature()
        }
    )
}

#Preview("Onboarding - welcome (light)") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(currentStep: .welcome)) {
            OnboardingFeature()
        }
    )
    .preferredColorScheme(.light)
}

#Preview("Onboarding - notifications") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(currentStep: .notifications)) {
            OnboardingFeature()
        }
    )
}
