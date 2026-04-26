import Charts
import SwiftUI

struct ChartDailySeriesCardView: View {
    let inspectedHour: HourlyPrice?
    let onInspectedHourChanged: (HourlyPrice) -> Void
    let prices: [HourlyPrice]

    private enum UIConstants {
        static let chartHeight: CGFloat = 240
        static let cornerRadius: CGFloat = 16
        static let markerLineWidth: CGFloat = 1
    }

    var body: some View {
        Chart {
            ForEach(prices, id: \.date) { entry in
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

            if let currentHourEntry {
                RuleMark(
                    x: .value(String(localized: "chart.axis.hour"), currentHourEntry.date)
                )
                .lineStyle(.init(lineWidth: UIConstants.markerLineWidth, dash: [4]))
                .foregroundStyle(Color.secondary)
                .annotation(position: .top, alignment: .leading) {
                    Text(String(localized: "chart.currentHour.badge"))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                }
            }

            if let inspectedHour {
                RuleMark(
                    x: .value(String(localized: "chart.axis.hour"), inspectedHour.date)
                )
                .lineStyle(.init(lineWidth: 2))
                .foregroundStyle(Color.orange)

                PointMark(
                    x: .value(String(localized: "chart.axis.hour"), inspectedHour.date),
                    y: .value(String(localized: "chart.axis.price"), inspectedHour.eurPerKWh)
                )
                .symbol(.circle)
                .symbolSize(80)
                .foregroundStyle(Color.orange)
            }
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let plotArea = geometry[plotFrame]
                                let xPosition = value.location.x - plotArea.origin.x
                                guard xPosition >= 0, xPosition <= plotArea.width else { return }
                                guard let date: Date = proxy.value(atX: xPosition) else { return }
                                if let nearest = nearestPrice(to: date), nearest != inspectedHour {
                                    onInspectedHourChanged(nearest)
                                }
                            }
                    )
                    .accessibilityIdentifier("chartInteractionOverlay")
            }
        }
        .frame(height: UIConstants.chartHeight)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var currentHourEntry: HourlyPrice? {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        return prices.first { entry in
            calendar.isDate(entry.date, equalTo: now, toGranularity: .hour)
        }
    }

    private func nearestPrice(to date: Date) -> HourlyPrice? {
        prices.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
        }
    }
}
