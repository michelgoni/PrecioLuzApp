import Foundation

enum Daypart: String, CaseIterable, Equatable, Sendable {
    case overnight
    case morning
    case afternoon
    case night

    static func from(date: Date, calendar: Calendar) -> Self {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0...5:
            return .overnight
        case 6...11:
            return .morning
        case 12...17:
            return .afternoon
        default:
            return .night
        }
    }
}

enum PriceClassification: Equatable, Sendable {
    case cheap
    case expensive
    case mid
}

struct HourlyPrice: Equatable, Sendable {
    var classification: PriceClassification
    var date: Date
    var daypart: Daypart
    var eurPerKWh: Double

    init(classification: PriceClassification, date: Date, daypart: Daypart, eurPerKWh: Double) {
        self.classification = classification
        self.date = date
        self.daypart = daypart
        self.eurPerKWh = eurPerKWh
    }

    init(classification: PriceClassification, raw: PricingClient.HourPrice, calendar: Calendar) {
        self.init(
            classification: classification,
            date: raw.date,
            daypart: Daypart.from(date: raw.date, calendar: calendar),
            eurPerKWh: raw.eurPerKWh
        )
    }

    func isSameHour(as date: Date, calendar: Calendar) -> Bool {
        calendar.isDate(self.date, equalTo: date, toGranularity: .hour)
    }
}

struct PriceSummary: Equatable, Sendable {
    var average: Double
    var current: HourlyPrice?
    var maximum: Double
    var maximumHour: Date
    var minimum: Double
    var minimumHour: Date

    static func from(_ prices: [HourlyPrice]) -> Self? {
        guard let first = prices.first else { return nil }

        let average = prices.map(\.eurPerKWh).reduce(0, +) / Double(prices.count)
        let maximumEntry = prices.max { $0.eurPerKWh < $1.eurPerKWh } ?? first
        let minimumEntry = prices.min { $0.eurPerKWh < $1.eurPerKWh } ?? first

        return Self(
            average: average,
            current: nil,
            maximum: maximumEntry.eurPerKWh,
            maximumHour: maximumEntry.date,
            minimum: minimumEntry.eurPerKWh,
            minimumHour: minimumEntry.date
        )
    }
}

struct AppliancePreset: Equatable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case airConditioner
        case clothesDryer
        case dishwasher
        case electricHeater
        case electricVehicle
        case inductionCooktop
        case oven
        case washingMachine
        case waterHeater
    }

    var displayName: String
    var kind: Kind
    var powerKW: Double
    var shortDescription: String
    var symbolName: String
}

struct CostCalculation: Equatable, Sendable {
    var durationHours: Double
    var estimatedCostEUR: Double
    var preset: AppliancePreset
    var priceAppliedEURPerKWh: Double
    var selectedHour: HourlyPrice
}

struct NotificationSettings: Equatable, Sendable {
    var customThresholdEnabled: Bool
    var customThresholdEURPerKWh: Double?
    var notificationsEnabled: Bool
    var notifyDailyMaximum: Bool
    var notifyDailyMinimum: Bool
}

enum HourlyPriceClassifier {
    private struct IndexedPrice {
        let index: Int
        let price: PricingClient.HourPrice
    }

    static func classify(_ prices: [PricingClient.HourPrice], calendar: Calendar) -> [HourlyPrice] {
        guard !prices.isEmpty else { return [] }

        let indexedPrices = prices.enumerated().map {
            IndexedPrice(index: $0.offset, price: $0.element)
        }
        let (cheapIndices, expensiveIndices) = bucketIndices(for: indexedPrices)

        return indexedPrices.map { entry in
            let classification: PriceClassification
            if cheapIndices.contains(entry.index) {
                classification = .cheap
            } else if expensiveIndices.contains(entry.index) {
                classification = .expensive
            } else {
                classification = .mid
            }

            return HourlyPrice(
                classification: classification,
                raw: entry.price,
                calendar: calendar
            )
        }
    }

    private static func bucketIndices(for prices: [IndexedPrice]) -> (cheap: Set<Int>, expensive: Set<Int>) {
        let count = prices.count
        guard count > 1 else { return ([], []) }

        let sorted = prices.sorted {
            if $0.price.eurPerKWh == $1.price.eurPerKWh {
                return $0.price.date < $1.price.date
            }
            return $0.price.eurPerKWh < $1.price.eurPerKWh
        }

        let baseSize = count / 3
        let cheapSize = max(1, baseSize)
        let expensiveSize = max(1, baseSize)

        let cheap = Set(sorted.prefix(cheapSize).map(\.index))
        let expensive = Set(sorted.suffix(expensiveSize).map(\.index))
        return (cheap, expensive)
    }
}

enum DailyPriceSummaryBuilder {
    static func makeSummary(from prices: [HourlyPrice]) -> PriceSummary? {
        PriceSummary.from(prices)
    }

    static func makeSummary(from prices: [HourlyPrice], now: Date, calendar: Calendar) -> PriceSummary? {
        PriceSummary.from(prices)?.withCurrent(from: prices, matching: now, calendar: calendar)
    }
}

enum ApplianceCostEstimator {
    static func estimate(durationHours: Double, preset: AppliancePreset, selectedHour: HourlyPrice) -> CostCalculation {
        let estimatedCostEUR = selectedHour.eurPerKWh * preset.powerKW * durationHours
        return CostCalculation(
            durationHours: durationHours,
            estimatedCostEUR: estimatedCostEUR,
            preset: preset,
            priceAppliedEURPerKWh: selectedHour.eurPerKWh,
            selectedHour: selectedHour
        )
    }
}

private extension PriceSummary {
    func withCurrent(from prices: [HourlyPrice], matching date: Date, calendar: Calendar) -> Self {
        var summary = self
        summary.current = prices.first { $0.isSameHour(as: date, calendar: calendar) }
        return summary
    }
}
