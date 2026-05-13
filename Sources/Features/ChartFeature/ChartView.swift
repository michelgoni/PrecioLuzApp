import ComposableArchitecture
import SwiftUI

struct ChartView: View {
    let store: StoreOf<ChartFeature>

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

                ZStack {
                    if sortedFilteredPrices.isEmpty {
                        ChartEmptyStateCardView()
                            .transition(.opacity)
                    } else {
                        VStack(alignment: .leading, spacing: UIConstants.verticalSpacing) {
                            ChartDailySeriesCardView(
                                inspectedHour: store.inspectedHour,
                                onInspectedHourChanged: {
                                    store.send(.inspectedHourChanged($0))
                                },
                                prices: sortedFilteredPrices
                            )
                            .id(store.selectedDaypart)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))

                            if let inspectedHour = store.inspectedHour {
                                ChartInspectionCardView(entry: inspectedHour)
                                    .id(inspectedHour.date)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                }
                .animation(MotionTokens.standard, value: store.selectedDaypart)
                .animation(MotionTokens.gentleSpring, value: store.inspectedHour?.date)
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
            get: { store.selectedDaypart },
            set: { store.send(.selectedDaypartChanged($0)) }
        )
    }

    private var sortedFilteredPrices: [HourlyPrice] {
        store.filteredPrices.sorted { $0.date < $1.date }
    }
}
