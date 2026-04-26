import ComposableArchitecture
import Foundation

struct ChartFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var hourlyPrices: [HourlyPrice] = []
        var inspectedHour: HourlyPrice?
        var selectedDaypart: Daypart = .morning

        var filteredPrices: [HourlyPrice] {
            hourlyPrices.filter { $0.daypart == selectedDaypart }
        }
    }

    enum Action: Equatable {
        case inspectedHourChanged(HourlyPrice?)
        case selectedDaypartChanged(Daypart)
        case syncHourlyPrices([HourlyPrice])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .inspectedHourChanged(hour):
                state.inspectedHour = hour
                return .none

            case let .selectedDaypartChanged(daypart):
                state.selectedDaypart = daypart
                reconcileInspectedHour(&state)
                return .none

            case let .syncHourlyPrices(hourlyPrices):
                state.hourlyPrices = hourlyPrices
                reconcileInspectedHour(&state)
                return .none
            }
        }
    }

    private func reconcileInspectedHour(_ state: inout State) {
        guard let inspectedHour = state.inspectedHour else { return }
        let isStillVisible = state.filteredPrices.contains { candidate in
            candidate.date == inspectedHour.date
        }
        if !isStillVisible {
            state.inspectedHour = nil
        }
    }
}
