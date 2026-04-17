import Foundation

struct DailyPricingSnapshotPayload: Equatable, Sendable {
    var dayStart: Date
    var fetchedAt: Date
    var hourlyPrices: [HourlyPrice]
    var summary: PriceSummary?
}

enum DailyPricingSnapshotPipelineResult: Equatable, Sendable {
    case cached(DailyPricingSnapshotPayload)
    case failed
    case fresh(DailyPricingSnapshotPayload)
}

struct DailyPricingSnapshotPipeline: Sendable {
    private typealias Payload = DailyPricingSnapshotPayload
    typealias PipelineResult = DailyPricingSnapshotPipelineResult
    private typealias RawPrices = [PricingClient.HourPrice]
    private static let retentionDays = 30

    let dateClient: DateClient
    let persistenceClient: PersistenceClient
    let pricingClient: PricingClient

    func load(for day: Date? = nil) async -> PipelineResult {
        let now = dateClient.now()
        let timeZone = dateClient.timeZone()
        var calendar = dateClient.calendar()
        calendar.timeZone = timeZone

        let targetDay = day ?? now
        let dayStart = calendar.startOfDay(for: targetDay)

        let rawHourlyPrices: RawPrices
        do {
            rawHourlyPrices = try await pricingClient.fetchDailyPrices(dayStart, timeZone)
        } catch {
            return await loadCachedResult(
                dayStart: dayStart,
                now: now,
                timeZone: timeZone,
                calendar: calendar
            )
        }

        let payload = makePayload(
            dayStart: dayStart,
            fetchedAt: now,
            now: now,
            rawPrices: rawHourlyPrices,
            calendar: calendar
        )
        await persistSnapshot(dayStart: dayStart, fetchedAt: now, rawPrices: rawHourlyPrices)
        return .fresh(payload)
    }

    private func loadCachedResult(dayStart: Date, now: Date, timeZone: TimeZone, calendar: Calendar)
    async -> PipelineResult {
        do {
            guard let snapshot = try await persistenceClient.loadSnapshot(dayStart, timeZone) else {
                return .failed
            }

            let payload = makePayload(
                dayStart: snapshot.dayStart,
                fetchedAt: snapshot.fetchedAt,
                now: now,
                rawPrices: snapshot.hourlyPrices,
                calendar: calendar
            )
            return .cached(payload)
        } catch {
            return .failed
        }
    }

    private func makePayload(dayStart: Date, fetchedAt: Date, now: Date, rawPrices: RawPrices, calendar: Calendar)
    -> Payload {
        let hourlyPrices = HourlyPriceClassifier.classify(rawPrices, calendar: calendar)
        let summary = DailyPriceSummaryBuilder.makeSummary(from: hourlyPrices, now: now, calendar: calendar)
        return DailyPricingSnapshotPayload(
            dayStart: dayStart,
            fetchedAt: fetchedAt,
            hourlyPrices: hourlyPrices,
            summary: summary
        )
    }

    private func persistSnapshot(dayStart: Date, fetchedAt: Date, rawPrices: RawPrices) async {
        do {
            try await persistenceClient.saveSnapshot(
                .init(
                    dayStart: dayStart,
                    fetchedAt: fetchedAt,
                    hourlyPrices: rawPrices
                )
            )
            try await persistenceClient.pruneSnapshots(Self.retentionDays)
        } catch {
        }
    }
}
