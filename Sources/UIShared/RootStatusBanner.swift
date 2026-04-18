import SwiftUI

struct RootStatusBanner: View {
  let onRetry: () -> Void
  let status: RootStatus

  var body: some View {
    HStack(spacing: 8) {
        Spacer()
      Image(systemName: iconName)
        .foregroundStyle(tintColor)
      Text(label)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(tintColor)
        .accessibilityIdentifier("appRootStatusLabel")
      Spacer(minLength: 0)
      if status == .error {
        Button("Reintentar") {
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
        .fill(backgroundColor)
    )
  }

  private var backgroundColor: Color {
    switch status {
    case .cached:
      Color.orange.opacity(0.15)
    case .content:
      Color.green.opacity(0.15)
    case .empty:
      Color.yellow.opacity(0.15)
    case .error:
      Color.red.opacity(0.15)
    case .loading:
      Color.blue.opacity(0.15)
    }
  }

  private var iconName: String {
    switch status {
    case .cached:
      "clock.arrow.circlepath"
    case .content:
      "checkmark.circle"
    case .empty:
      "tray"
    case .error:
      "exclamationmark.triangle"
    case .loading:
      "arrow.clockwise"
    }
  }

  private var label: String {
    switch status {
    case .cached:
      "Usando caché"
    case .content:
      "Datos actualizados"
    case .empty:
      "Sin datos disponibles"
    case .error:
      "No se han podido cargar datos"
    case .loading:
      "Cargando precios..."
    }
  }

  private var tintColor: Color {
    switch status {
    case .cached:
      .orange
    case .content:
      .green
    case .empty:
      .yellow
    case .error:
      .red
    case .loading:
      .blue
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
