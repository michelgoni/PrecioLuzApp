import ComposableArchitecture
import Foundation

extension PricingClient: DependencyKey {
  static let liveValue = PricingClient.esiosLive()

  static let testValue = PricingClient { day, timeZone in
    StubPricingModel.makeDailyPrices(for: day, timeZone: timeZone)
  }
}

extension DependencyValues {
  var pricingClient: PricingClient {
    get { self[PricingClient.self] }
    set { self[PricingClient.self] = newValue }
  }
}
