import SnapshotTesting
import SwiftUI
import Testing

@testable import PrecioLuzApp

@MainActor
struct PricesMediumWidgetSnapshotTests {
    private let isCI: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["CI"] == "true" || environment["GITHUB_ACTIONS"] == "true"
    }()

    @Test("Snapshot: medium widget content state remains visually stable")
    func contentState() {
        guard !isCI else { return }
        assertSnapshot(
            of: PricesMediumWidgetView(model: .snapshotContentModel)
                .preferredColorScheme(.dark),
            as: .image(layout: .fixed(width: 338, height: 158))
        )
    }

    @Test("Snapshot: medium widget empty state remains visually stable")
    func emptyState() {
        guard !isCI else { return }
        assertSnapshot(
            of: PricesMediumWidgetView(model: .snapshotEmptyModel)
                .preferredColorScheme(.dark),
            as: .image(layout: .fixed(width: 338, height: 158))
        )
    }
}

private extension PricesMediumWidgetPresentationModel {
    static let snapshotContentModel = Self(
        barSeries: [
            .init(level: .neutral, normalizedHeight: 0.40),
            .init(level: .neutral, normalizedHeight: 0.30),
            .init(level: .cheap, normalizedHeight: 0.25),
            .init(level: .neutral, normalizedHeight: 0.35),
            .init(level: .neutral, normalizedHeight: 0.50),
            .init(level: .mid, normalizedHeight: 0.65),
            .init(level: .neutral, normalizedHeight: 0.55),
            .init(level: .neutral, normalizedHeight: 0.45),
            .init(level: .expensive, normalizedHeight: 0.80),
            .init(level: .expensive, normalizedHeight: 0.95),
            .init(level: .neutral, normalizedHeight: 0.70),
            .init(level: .neutral, normalizedHeight: 0.60)
        ],
        currentPriceText: "0,142",
        currentSlotLabel: String(localized: "prices.classification.mid"),
        nextHours: [
            .init(hourText: "11:00", level: .cheap, priceText: "0,109"),
            .init(hourText: "12:00", level: .mid, priceText: "0,136"),
            .init(hourText: "13:00", level: .cheap, priceText: "0,098")
        ],
        state: .content,
        timeWindowLabel: "10:00 · \(String(localized: "prices.hourly.current.badge"))"
    )

    static let snapshotEmptyModel = Self(
        barSeries: [],
        currentPriceText: "—",
        currentSlotLabel: String(localized: "widget.medium.empty.slot"),
        nextHours: [],
        state: .empty,
        timeWindowLabel: String(localized: "widget.medium.empty.timeWindow")
    )
}
