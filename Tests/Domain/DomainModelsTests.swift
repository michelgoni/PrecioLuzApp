import Foundation
import Testing

@testable import PrecioLuzApp

struct DomainModelsTests {
  @Test("Daypart maps hour ranges correctly")
  func daypartMapping() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let start = calendar.startOfDay(for: day)

    let overnight = try #require(calendar.date(byAdding: .hour, value: 1, to: start))
    let morning = try #require(calendar.date(byAdding: .hour, value: 7, to: start))
    let afternoon = try #require(calendar.date(byAdding: .hour, value: 13, to: start))
    let night = try #require(calendar.date(byAdding: .hour, value: 20, to: start))

    #expect(Daypart.from(date: overnight, calendar: calendar) == .overnight)
    #expect(Daypart.from(date: morning, calendar: calendar) == .morning)
    #expect(Daypart.from(date: afternoon, calendar: calendar) == .afternoon)
    #expect(Daypart.from(date: night, calendar: calendar) == .night)
  }

  @Test("Classification uses stable terciles with deterministic tie-breaking by date")
  func stableTercileClassification() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let start = calendar.startOfDay(for: day)

    let raw: [PricingClient.HourPrice] = [
      .init(date: try #require(calendar.date(byAdding: .hour, value: 0, to: start)), eurPerKWh: 0.20),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 1, to: start)), eurPerKWh: 0.10),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 2, to: start)), eurPerKWh: 0.20),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 3, to: start)), eurPerKWh: 0.30),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 4, to: start)), eurPerKWh: 0.10),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 5, to: start)), eurPerKWh: 0.30)
    ]

    let classified = HourlyPriceClassifier.classify(raw, calendar: calendar)

    #expect(classified.count == 6)
    #expect(classified[1].classification == .cheap)
    #expect(classified[4].classification == .cheap)
    #expect(classified[0].classification == .mid)
    #expect(classified[2].classification == .mid)
    #expect(classified[3].classification == .expensive)
    #expect(classified[5].classification == .expensive)
  }

  @Test("Classification handles small collections without arbitrary empty buckets")
  func smallCollectionClassification() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let start = calendar.startOfDay(for: day)

    let twoHours: [PricingClient.HourPrice] = [
      .init(date: try #require(calendar.date(byAdding: .hour, value: 0, to: start)), eurPerKWh: 0.30),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 1, to: start)), eurPerKWh: 0.10)
    ]

    let oneHour: [PricingClient.HourPrice] = [
      .init(date: try #require(calendar.date(byAdding: .hour, value: 2, to: start)), eurPerKWh: 0.20)
    ]

    let classifiedTwo = HourlyPriceClassifier.classify(twoHours, calendar: calendar)
    let classifiedOne = HourlyPriceClassifier.classify(oneHour, calendar: calendar)

    #expect(classifiedTwo.count == 2)
    #expect(classifiedTwo[0].classification == .expensive)
    #expect(classifiedTwo[1].classification == .cheap)
    #expect(classifiedOne.count == 1)
    #expect(classifiedOne[0].classification == .mid)
  }

  @Test("Daily summary computes current, average, minimum and maximum")
  func dailySummary() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let start = calendar.startOfDay(for: day)

    let raw: [PricingClient.HourPrice] = [
      .init(date: try #require(calendar.date(byAdding: .hour, value: 0, to: start)), eurPerKWh: 0.10),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 1, to: start)), eurPerKWh: 0.20),
      .init(date: try #require(calendar.date(byAdding: .hour, value: 2, to: start)), eurPerKWh: 0.30)
    ]

    let classified = HourlyPriceClassifier.classify(raw, calendar: calendar)
    let now = try #require(calendar.date(byAdding: .hour, value: 1, to: start))
    let summary = try #require(
      DailyPriceSummaryBuilder.makeSummary(from: classified, now: now, calendar: calendar)
    )

    #expect(summary.current?.eurPerKWh == 0.20)
    #expect(summary.minimum == 0.10)
    #expect(summary.maximum == 0.30)
    #expect(summary.minimumHour == raw[0].date)
    #expect(summary.maximumHour == raw[2].date)
    let epsilon = 0.000_001
    #expect(abs(summary.average - 0.20) < epsilon)
  }

  @Test("Cost formula multiplies price by power and duration")
  func costFormula() {
    let selectedHour = HourlyPrice(
      classification: .mid,
      date: Date(timeIntervalSince1970: 0),
      daypart: .morning,
      eurPerKWh: 0.25
    )
    let preset = AppliancePreset(
      displayName: "Lavadora",
      kind: .washingMachine,
      powerKW: 1.8,
      shortDescription: "Eco cycle",
      symbolName: "washer"
    )

    let calculation = ApplianceCostEstimator.estimate(
      durationHours: 2.0,
      preset: preset,
      selectedHour: selectedHour
    )

    let epsilon = 0.000_001
    #expect(abs(calculation.estimatedCostEUR - 0.9) < epsilon)
    #expect(calculation.priceAppliedEURPerKWh == 0.25)
  }
}
