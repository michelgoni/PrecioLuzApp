import SwiftUI

struct ChartView: View {
    let send: (ChartFeature.Action) -> Void
    let state: ChartFeature.State

    var body: some View {
        Color(.systemBackground)
            .accessibilityIdentifier("chartScreen")
            .ignoresSafeArea()
    }
}

#Preview("Chart placeholder") {
    ChartView(send: { _ in }, state: ChartFeature.State())
}
