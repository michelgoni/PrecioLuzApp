import SwiftUI

struct SettingsRowLabel: View {
    enum IconTint {
        case blue
        case green
        case orange
        case red
        case teal
        case indigo

        var symbol: Color {
            switch self {
            case .blue:
                return .blue
            case .green:
                return .green
            case .orange:
                return .orange
            case .red:
                return .red
            case .teal:
                return .teal
            case .indigo:
                return .indigo
            }
        }

        var background: Color {
            symbol.opacity(0.16)
        }
    }

    let systemImage: String
    let title: String
    let iconTint: IconTint

    var body: some View {
        HStack(spacing: SettingsRowLabelLayout.iconSpacing) {
            Image(systemName: systemImage)
                .font(.system(size: SettingsRowLabelLayout.iconSize, weight: .semibold))
                .foregroundStyle(iconTint.symbol)
                .frame(width: SettingsRowLabelLayout.iconCircle, height: SettingsRowLabelLayout.iconCircle)
                .background(iconTint.background, in: Circle())
                .accessibilityHidden(true)
            Text(title)
        }
    }
}

private enum SettingsRowLabelLayout {
    static let iconCircle: CGFloat = 28
    static let iconSize: CGFloat = 14
    static let iconSpacing: CGFloat = 12
}
