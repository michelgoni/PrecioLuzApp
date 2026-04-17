import ComposableArchitecture
import Foundation

struct PricingClient: Sendable {
  var fetchDailyPrices: @Sendable (_ day: Date, _ timeZone: TimeZone) async throws -> [HourPrice]
}

extension PricingClient {
  struct HourPrice: Equatable, Sendable {
    var date: Date
    var eurPerKWh: Double
  }
}

extension PricingClient: DependencyKey {
  static let liveValue = PricingClient { day, timeZone in
    StubPricingModel.makeDailyPrices(for: day, timeZone: timeZone)
  }

  static let testValue = PricingClient { day, timeZone in
    StubPricingModel.makeDailyPrices(for: day, timeZone: timeZone)
  }
}

private enum StubPricingModel {
  static let basePriceEURPerKWh = 0.10
  static let hourlyStepEURPerKWh = 0.005
  static let hourlyCount = 24

  static func makeDailyPrices(for day: Date, timeZone: TimeZone) -> [PricingClient.HourPrice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let startOfDay = calendar.startOfDay(for: day)

    return (0..<hourlyCount).map { hour in
      let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
      let price = basePriceEURPerKWh + Double(hour) * hourlyStepEURPerKWh
      return PricingClient.HourPrice(date: hourDate, eurPerKWh: price)
    }
  }
}

extension DependencyValues {
  var pricingClient: PricingClient {
    get { self[PricingClient.self] }
    set { self[PricingClient.self] = newValue }
  }
}
