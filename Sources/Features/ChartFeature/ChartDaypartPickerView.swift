import SwiftUI

struct ChartDaypartPickerView: View {
    @Binding var selectedDaypart: Daypart

    var body: some View {
        Picker(
            String(localized: "chart.daypart.picker"),
            selection: $selectedDaypart
        ) {
            ForEach(Daypart.allCases, id: \.self) { daypart in
                Text(daypart.localizedName)
                    .tag(daypart)
            }
        }
        .accessibilityIdentifier("chartDaypartPicker")
        .pickerStyle(.segmented)
    }
}

extension Daypart {
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
