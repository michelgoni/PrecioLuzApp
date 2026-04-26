import ComposableArchitecture
import SwiftUI

struct ChartView: View {
    let store: StoreOf<AppFeature>

    private enum UIConstants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.verticalSpacing) {
                Text(String(localized: "chart.daily.title"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("chartTitle")

                ChartDaypartPickerView(selectedDaypart: selectedDaypartBinding)

                if sortedFilteredPrices.isEmpty {
                    ChartEmptyStateCardView()
                } else {
                    ChartDailySeriesCardView(
                        inspectedHour: store.chart.inspectedHour,
                        onInspectedHourChanged: {
                            store.send(.chart(.inspectedHourChanged($0)))
                        },
                        prices: sortedFilteredPrices
                    )
                    if let inspectedHour = store.chart.inspectedHour {
                        ChartInspectionCardView(entry: inspectedHour)
                    }
                }
            }
            .padding(.horizontal, UIConstants.horizontalPadding)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .accessibilityIdentifier("chartScreen")
        .background(Color(.systemBackground))
    }

    private var selectedDaypartBinding: Binding<Daypart> {
        Binding(
            get: { store.chart.selectedDaypart },
            set: { store.send(.chart(.selectedDaypartChanged($0))) }
        )
    }

    private var sortedFilteredPrices: [HourlyPrice] {
        store.chart.filteredPrices.sorted { $0.date < $1.date }
    }
}
