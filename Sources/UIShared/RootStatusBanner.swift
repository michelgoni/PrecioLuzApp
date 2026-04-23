import SwiftUI

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
