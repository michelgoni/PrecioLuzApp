import ComposableArchitecture
import SwiftUI

struct ChartView: View {
    let store: StoreOf<ChartFeature>

    var body: some View {
        Color(.systemBackground)
            .accessibilityIdentifier("chartScreen")
            .ignoresSafeArea()
    }
}

#Preview("Chart placeholder") {
    ChartView(
        store: Store(initialState: ChartFeature.State()) {
            ChartFeature()
        }
    )
}
