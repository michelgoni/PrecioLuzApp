import SwiftUI

enum MotionTokens {
    static let entranceDelayStep = 0.035
    static let pressedScale: CGFloat = 0.97
    static let quick = Animation.easeOut(duration: 0.16)
    static let reducedMotionScale: CGFloat = 1
    static let shimmerAngle: Double = 12
    static let shimmerDuration = 1.35
    static let standard = Animation.easeInOut(duration: 0.24)
    static let standardOffset: CGFloat = 8

    static var gentleSpring: Animation {
        .spring(response: 0.28, dampingFraction: 0.86, blendDuration: 0.12)
    }

    static var shimmer: Animation {
        .linear(duration: shimmerDuration).repeatForever(autoreverses: false)
    }
}

struct ReduceMotionAwareOffsetModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.offset(x: reduceMotion ? 0 : x, y: reduceMotion ? 0 : y)
    }
}

struct ReduceMotionAwareScaleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let scale: CGFloat

    func body(content: Content) -> some View {
        content.scaleEffect(reduceMotion ? MotionTokens.reducedMotionScale : scale)
    }
}

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !reduceMotion {
                    GeometryReader { geometry in
                        shimmerBand(width: geometry.size.width)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                updateAnimationState()
            }
            .onChange(of: isActive) { _, _ in
                updateAnimationState()
            }
            .onChange(of: reduceMotion) { _, _ in
                updateAnimationState()
            }
    }

    private func shimmerBand(width: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.24),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(.degrees(MotionTokens.shimmerAngle))
            .offset(x: isAnimating ? width : -width)
    }

    private func updateAnimationState() {
        guard isActive, !reduceMotion else {
            isAnimating = false
            return
        }
        isAnimating = false
        withAnimation(MotionTokens.shimmer) {
            isAnimating = true
        }
    }
}

struct PressedFeedbackButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.94 : 1)
            .reduceMotionAwareScale(configuration.isPressed && !reduceMotion ? MotionTokens.pressedScale : 1)
            .animation(MotionTokens.quick, value: configuration.isPressed)
    }
}

struct StaggeredEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let index: Int
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .opacity(trigger ? 1 : 0)
            .reduceMotionAwareOffset(y: trigger ? 0 : MotionTokens.standardOffset)
            .animation(animation, value: trigger)
    }

    private var animation: Animation {
        guard !reduceMotion else {
            return MotionTokens.quick
        }
        return MotionTokens.gentleSpring.delay(Double(index) * MotionTokens.entranceDelayStep)
    }
}

struct RootStatusBanner: View {
  let onRetry: () -> Void
  let status: RootStatus

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: style.iconName)
        .foregroundStyle(style.tintColor)
      Text(style.label)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(style.tintColor)
        .accessibilityIdentifier("appRootStatusLabel")
      Spacer(minLength: 0)
      if status == .error {
        Button(
          String(localized: "app.rootStatus.retry.button")
        ) {
          onRetry()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .accessibilityIdentifier("appRootStatusRetryButton")
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(style.backgroundColor)
    )
  }

  private var style: RootStatusBannerStyle {
    status.bannerStyle
  }
}

private struct RootStatusBannerStyle {
  let backgroundColor: Color
  let iconName: String
  let label: String
  let tintColor: Color
}

private extension RootStatus {
  var bannerStyle: RootStatusBannerStyle {
    switch self {
    case .cached:
      RootStatusBannerStyle(
        backgroundColor: Color.orange.opacity(0.15),
        iconName: "clock.arrow.circlepath",
        label: String(localized: "app.rootStatus.cached.label"),
        tintColor: .orange
      )
    case .content:
      RootStatusBannerStyle(
        backgroundColor: Color.green.opacity(0.15),
        iconName: "checkmark.circle",
        label: String(localized: "app.rootStatus.content.label"),
        tintColor: .green
      )
    case .empty:
      RootStatusBannerStyle(
        backgroundColor: Color.yellow.opacity(0.15),
        iconName: "tray",
        label: String(localized: "app.rootStatus.empty.label"),
        tintColor: .yellow
      )
    case .error:
      RootStatusBannerStyle(
        backgroundColor: Color.red.opacity(0.15),
        iconName: "exclamationmark.triangle",
        label: String(localized: "app.rootStatus.error.label"),
        tintColor: .red
      )
    case .loading:
      RootStatusBannerStyle(
        backgroundColor: Color.blue.opacity(0.15),
        iconName: "arrow.clockwise",
        label: String(localized: "app.rootStatus.loading.label"),
        tintColor: .blue
      )
    }
  }
}

#Preview("Loading") {
  RootStatusBanner(
    onRetry: {},
    status: .loading
  )
  .padding()
}

#Preview("Error") {
  RootStatusBanner(
    onRetry: {},
    status: .error
  )
  .padding()
}

#Preview("Todos los estados") {
  VStack(spacing: 12) {
    RootStatusBanner(onRetry: {}, status: .loading)
    RootStatusBanner(onRetry: {}, status: .content)
    RootStatusBanner(onRetry: {}, status: .cached)
    RootStatusBanner(onRetry: {}, status: .empty)
    RootStatusBanner(onRetry: {}, status: .error)
  }
  .padding()
}

extension View {
    func staggeredEntrance(index: Int, trigger: Bool) -> some View {
        modifier(StaggeredEntranceModifier(index: index, trigger: trigger))
    }

    func reduceMotionAwareOffset(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        modifier(ReduceMotionAwareOffsetModifier(x: x, y: y))
    }

    func reduceMotionAwareScale(_ scale: CGFloat) -> some View {
        modifier(ReduceMotionAwareScaleModifier(scale: scale))
    }

    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
