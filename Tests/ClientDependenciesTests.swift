import ComposableArchitecture
import Foundation
import Testing

@testable import PrecioLuzApp

struct ClientDependenciesTests {
  @Test("PricingClient testValue returns 24 deterministic hourly prices")
  func pricingClientTestValueProduces24HourlyPrices() async throws {
    let day = Date(timeIntervalSince1970: 1_700_000_000)
      let prices = try await PricingClient.testValue.fetchDailyPrices(day, TimeZone(secondsFromGMT: .zero)!)

    #expect(prices.count == 24)
    let firstPrice = try #require(prices.first?.eurPerKWh)
    let lastPrice = try #require(prices.last?.eurPerKWh)
    let epsilon = 0.000_001
    #expect(abs(firstPrice - 0.10) < epsilon)
    #expect(abs(lastPrice - 0.215) < epsilon)
  }

  @Test("DateClient testValue returns deterministic now and timezone")
  func dateClientTestValueIsDeterministic() {
      #expect(DateClient.testValue.now() == Date(timeIntervalSince1970: .zero))
      #expect(DateClient.testValue.timeZone() == TimeZone(secondsFromGMT: .zero))
  }

  @Test("NotificationClient testValue reports authorized status")
  func notificationClientTestValueIsAuthorized() async {
    let status = await NotificationClient.testValue.authorizationStatus()
    #expect(status == .authorized)
  }

  @Test("PersistenceClient testValue returns no snapshot by default")
  func persistenceClientTestValueReturnsNoSnapshot() async throws {
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let snapshot = try await PersistenceClient.testValue.loadSnapshot(day, .current)

    #expect(snapshot == nil)
  }
}
