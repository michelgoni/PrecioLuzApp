import ComposableArchitecture
import Foundation

enum HourlyListPresentationMode: String, CaseIterable, Equatable {
    case flatWithAvailabilityNotice
    case withDateHeaders
}

struct PricesFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var costCalculation = CostCalculationFeature.State()
        var hourlyListPresentationMode: HourlyListPresentationMode = .withDateHeaders
        var hourlyPrices: [HourlyPrice] = []
        var isFromCache = false
        var isLoading = true
        var summary: PriceSummary?
        var visibleHourlyPrices: [HourlyPrice] = []
    }

    enum Action: Equatable {
        case costCalculation(CostCalculationFeature.Action)
        case hourTapped(HourlyPrice)
        case snapshotLoaded(DailyPricingSnapshotPayload, isCached: Bool)
    }

    @Dependency(\.dateClient) var dateClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .hourTapped(hour):
                guard state.isVisibleHour(hour) else {
                    return .none
                }
                CostCalculationFeature.State.apply(.hourSelected(hour), to: &state.costCalculation)
                return .none

            case let .snapshotLoaded(payload, isCached):
                state.applySnapshot(
                    payload,
                    isCached: isCached,
                    now: dateClient.now(),
                    calendar: dateClient.currentCalendar()
                )
                return .none

            case let .costCalculation(costAction):
                CostCalculationFeature.State.apply(costAction, to: &state.costCalculation)
                return .none
            }
        }
    }
}

extension PricesFeature.State {
    mutating func applySnapshot(_ payload: DailyPricingSnapshotPayload, isCached: Bool, now: Date, calendar: Calendar) {
        hourlyPrices = payload.hourlyPrices
        isFromCache = isCached
        isLoading = false
        summary = payload.summary
        refreshVisibleHours(now: now, calendar: calendar)
        reconcileSelectedHour()
    }

    func isVisibleHour(_ hour: HourlyPrice) -> Bool {
        visibleHourlyPrices.contains { $0.date == hour.date }
    }

    func presentationCurrentHourDate(now: Date, calendar: Calendar) -> Date? {
        hourlyPrices.first { calendar.isDate($0.date, equalTo: now, toGranularity: .hour) }?.date
    }

    func presentationSummary(now: Date, calendar: Calendar) -> PriceSummary? {
        guard var summary else { return nil }
        summary.current = hourlyPrices.first { $0.isSameHour(as: now, calendar: calendar) }
        return summary
    }

    func presentationNow(timelineDate: Date, calendar: Calendar) -> Date {
        return timelineDate
    }

    func presentationVisibleHourlyPrices(now: Date, calendar: Calendar) -> [HourlyPrice] {
        let currentHourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return hourlyPrices.filter { $0.date >= currentHourStart }
    }

    mutating func refreshVisibleHours(now: Date, calendar: Calendar) {
        let currentHourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        visibleHourlyPrices = hourlyPrices.filter { $0.date >= currentHourStart }
    }

    private mutating func reconcileSelectedHour() {
        costCalculation.selectedHour = visibleHourlyPrices.first {
            $0.date == costCalculation.selectedHour?.date
        }
        if costCalculation.selectedHour == nil {
            costCalculation.isPresented = false
        }
    }
}

private extension DateClient {
    func currentCalendar() -> Calendar {
        var calendar = calendar()
        calendar.timeZone = timeZone()
        return calendar
    }
}
