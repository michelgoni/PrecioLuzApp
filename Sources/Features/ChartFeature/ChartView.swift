import Charts
import SwiftUI

struct ChartView: View {
    let send: (ChartFeature.Action) -> Void
    let state: ChartFeature.State

    private enum UIConstants {
        static let chartHeight: CGFloat = 240
        static let cornerRadius: CGFloat = 16
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

                Picker(
                    String(localized: "chart.daypart.picker"),
                    selection: selectedDaypartBinding
                ) {
                    ForEach(Daypart.allCases, id: \.self) { daypart in
                        Text(daypart.localizedName)
                            .tag(daypart)
                    }
                }
                .accessibilityIdentifier("chartDaypartPicker")
                .pickerStyle(.segmented)

                if sortedFilteredPrices.isEmpty {
                    emptyStateCard
                } else {
                    chartCard
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
            get: { state.selectedDaypart },
            set: { send(.selectedDaypartChanged($0)) }
        )
    }

    private var sortedFilteredPrices: [HourlyPrice] {
        state.filteredPrices.sorted { $0.date < $1.date }
    }

    private var chartCard: some View {
        Chart(sortedFilteredPrices, id: \.date) { entry in
            LineMark(
                x: .value(String(localized: "chart.axis.hour"), entry.date),
                y: .value(String(localized: "chart.axis.price"), entry.eurPerKWh)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(.init(lineWidth: 2))
            .foregroundStyle(Color.accentColor)

            PointMark(
                x: .value(String(localized: "chart.axis.hour"), entry.date),
                y: .value(String(localized: "chart.axis.price"), entry.eurPerKWh)
            )
            .symbolSize(20)
            .foregroundStyle(Color.accentColor.opacity(0.8))
        }
        .accessibilityIdentifier("chartDailySeries")
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.hour().minute()))
                    }
                }
            }
        }
        .frame(height: UIConstants.chartHeight)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var emptyStateCard: some View {
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

private extension Daypart {
    var localizedName: String {
        switch self {
        case .overnight:
            String(localized: "chart.daypart.overnight")
        case .morning:
            String(localized: "chart.daypart.morning")
        case .afternoon:
            String(localized: "chart.daypart.afternoon")
        case .night:
            String(localized: "chart.daypart.night")
        }
    }
}
