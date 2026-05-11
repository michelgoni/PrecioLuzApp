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
    private typealias DayRawPrices = (dayStart: Date, rawPrices: RawPrices)
    private static let retentionDays = 30

    let dateClient: DateClient
    let persistenceClient: PersistenceClient
    let pricingClient: PricingClient

    func load(for day: Date? = nil) async -> PipelineResult {
        let now = dateClient.now()
        let timeZone = dateClient.timeZone()
        var calendar = dateClient.calendar()
        calendar.timeZone = timeZone

        let publicationWindowPolicy = REEPublicationWindowPolicy(calendar: calendar, timeZone: timeZone)
        let dayStarts = publicationWindowPolicy.dayStartsToLoad(now: now, requestedDay: day)

        var loadedDays: [DayRawPrices] = []
        var usedCache = false
        var shouldPruneSnapshots = false

        for dayStart in dayStarts {
            switch await loadDay(dayStart: dayStart, now: now, timeZone: timeZone) {
            case let .fresh(rawPrices):
                loadedDays.append((dayStart, rawPrices))
                shouldPruneSnapshots = true
            case let .cached(rawPrices):
                loadedDays.append((dayStart, rawPrices))
                usedCache = true
            case .failed:
                guard loadedDays.isEmpty else {
                    continue
                }
                return .failed
            }
        }

        let primaryDayStart = dayStarts.first ?? calendar.startOfDay(for: now)
        let payload = makePayload(
            dayStart: primaryDayStart,
            fetchedAt: now,
            now: now,
            dayRawPrices: loadedDays,
            calendar: calendar
        )
        if shouldPruneSnapshots {
            await pruneSnapshots()
        }
        return usedCache ? .cached(payload) : .fresh(payload)
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
                dayRawPrices: [(snapshot.dayStart, snapshot.hourlyPrices)],
                calendar: calendar
            )
            return .cached(payload)
        } catch {
            return .failed
        }
    }

    private func makePayload(
        dayStart: Date,
        fetchedAt: Date,
        now: Date,
        dayRawPrices: [DayRawPrices],
        calendar: Calendar
    ) -> Payload {
        let hourlyPrices = dayRawPrices
            .sorted { $0.dayStart < $1.dayStart }
            .flatMap { HourlyPriceClassifier.classify($0.rawPrices, calendar: calendar) }
            .sorted { $0.date < $1.date }

        let summaryDayPrices = hourlyPrices.filter {
            calendar.isDate($0.date, inSameDayAs: dayStart)
        }
        let summary = DailyPriceSummaryBuilder.makeSummary(
            from: summaryDayPrices,
            now: now,
            calendar: calendar
        )
        return DailyPricingSnapshotPayload(
            dayStart: dayStart,
            fetchedAt: fetchedAt,
            hourlyPrices: hourlyPrices,
            summary: summary
        )
    }

    private enum DayLoadResult: Equatable, Sendable {
        case cached(RawPrices)
        case failed
        case fresh(RawPrices)
    }

    private func loadDay(dayStart: Date, now: Date, timeZone: TimeZone) async -> DayLoadResult {
        do {
            let rawPrices = try await pricingClient.fetchDailyPrices(dayStart, timeZone)
            await persistSnapshot(dayStart: dayStart, fetchedAt: now, rawPrices: rawPrices)
            return .fresh(rawPrices)
        } catch {
            do {
                guard let snapshot = try await persistenceClient.loadSnapshot(dayStart, timeZone) else {
                    return .failed
                }
                return .cached(snapshot.hourlyPrices)
            } catch {
                return .failed
            }
        }
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
        } catch {
        }
    }

    private func pruneSnapshots() async {
        do {
            try await persistenceClient.pruneSnapshots(Self.retentionDays)
        } catch {
        }
    }
}
