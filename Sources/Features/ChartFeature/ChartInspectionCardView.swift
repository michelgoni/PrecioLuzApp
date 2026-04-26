import SwiftUI

struct ChartInspectionCardView: View {
    let entry: HourlyPrice

    private enum UIConstants {
        static let cornerRadius: CGFloat = 16
        static let rowSpacing: CGFloat = 16
    }

    var body: some View {
        HStack(spacing: UIConstants.rowSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "chart.inspection.hour"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.date.formatted(.dateTime.hour().minute()))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "chart.inspection.price"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(PricesViewFormatting.price(entry.eurPerKWh))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityIdentifier("chartInspectionCard")
    }
}
