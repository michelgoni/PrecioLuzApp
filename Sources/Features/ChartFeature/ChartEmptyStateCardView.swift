import SwiftUI

struct ChartEmptyStateCardView: View {
    private enum UIConstants {
        static let chartHeight: CGFloat = 240
        static let cornerRadius: CGFloat = 16
    }

    var body: some View {
        Text(String(localized: "chart.empty.daypart"))
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: UIConstants.chartHeight)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
            .accessibilityIdentifier("chartEmptyState")
    }
}
