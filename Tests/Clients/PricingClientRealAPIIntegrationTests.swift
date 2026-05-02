import Foundation
import Testing

@testable import PrecioLuzApp

struct PricingClientRealAPIIntegrationTests {
  @Test("ESIOS real API returns non-empty hourly prices for previous day when REE_API_KEY is configured")
  func esiosRealAPIProducesPrices() async throws {
    let key = ProcessInfo.processInfo.environment["REE_API_KEY"]?.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard let key, !key.isEmpty else {
      return
    }

    let timeZone = TimeZone(identifier: "Europe/Madrid") ?? .current
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let day = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

    let client = PricingClient.esiosLive(apiKeyProvider: { key })
    let prices = try await client.fetchDailyPrices(day, timeZone)

    #expect(!prices.isEmpty)
    #expect(prices.count >= 23)
    #expect(prices.count <= 25)
  }
}
