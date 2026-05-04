import Foundation
import Testing

@testable import PrecioLuzApp

struct PricingClientESIOSLiveTests {
  @Test("Local API key provider reads REE_API_KEY directly from environment")
  func localAPIKeyProviderReadsEnvironmentValue() {
    let key = LocalAPIKeyProvider.apiKey(
      environment: ["REE_API_KEY": " token-value "],
      readFile: { _ in nil }
    )

    #expect(key == "token-value")
  }

  @Test("Local API key provider reads REE_API_KEY from configured env file")
  func localAPIKeyProviderReadsEnvFile() {
    let key = LocalAPIKeyProvider.apiKey(
      environment: ["PRECIOLUZ_ENV_FILE": "/local/.env"],
      readFile: { path in
        #expect(path == "/local/.env")
        return """
        # Local development secrets
        \(["REE_API_KEY", "\"file-token\""].joined(separator: "="))
        """
      }
    )

    #expect(key == "file-token")
  }

  @Test("Local API key provider reads bundled Debug env resource")
  func localAPIKeyProviderReadsBundledEnvResource() {
    let key = LocalAPIKeyProvider.apiKey(
      environment: [:],
      readFile: { _ in nil },
      bundledEnvFileContents: {
        ["REE_API_KEY", "\"bundled-token\""].joined(separator: "=")
      }
    )

    #expect(key == "bundled-token")
  }

  @Test("ESIOS client maps PVPC hourly values and converts EUR/MWh to EUR/kWh")
  func mapsHourlyValuesForPeninsula() async throws {
    let day = Date(timeIntervalSince1970: 1_700_000_000)
    let payload = """
    {
      "indicator": {
        "values": [
          {
            "value": 100.0,
            "datetime": "2023-11-14T00:00:00.000+00:00",
            "geo_id": 8741
          },
          {
            "value": 150.0,
            "datetime": "2023-11-14T01:00:00.000+00:00",
            "geo_id": 8741
          },
          {
            "value": 999.0,
            "datetime": "2023-11-14T01:00:00.000+00:00",
            "geo_id": 8742
          }
        ]
      }
    }
    """
    let client = PricingClient.esiosLive(
      apiKeyProvider: { "token" },
      fetcher: { _ in
        let data = Data(payload.utf8)
        let response = HTTPURLResponse(
          url: URL(string: "https://api.esios.ree.es/indicators/1001")!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        return (data, response)
      }
    )

    let prices = try await client.fetchDailyPrices(day, TimeZone(secondsFromGMT: 0)!)

    #expect(prices.count == 2)
    #expect(prices[0].eurPerKWh == 0.1)
    #expect(prices[1].eurPerKWh == 0.15)
  }

  @Test("ESIOS client throws missing API key when REE_API_KEY is not provided")
  func throwsMissingAPIKey() async {
    let client = PricingClient.esiosLive(
      apiKeyProvider: { nil },
      fetcher: { _ in
        Issue.record("Fetcher should not run when API key is missing.")
        throw URLError(.badServerResponse)
      }
    )

    do {
      _ = try await client.fetchDailyPrices(.now, .current)
      Issue.record("Expected missing API key error.")
    } catch let error as PricingClientError {
      #expect(error == .missingAPIKey)
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("ESIOS client maps HTTP errors")
  func mapsHTTPError() async {
    let client = PricingClient.esiosLive(
      apiKeyProvider: { "token" },
      fetcher: { request in
        let data = Data("{\"errors\":[{\"status\":\"401\"}]}".utf8)
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 401,
          httpVersion: nil,
          headerFields: nil
        )!
        return (data, response)
      }
    )

    do {
      _ = try await client.fetchDailyPrices(.now, .current)
      Issue.record("Expected HTTP error.")
    } catch let error as PricingClientError {
      #expect(error == .requestFailed(statusCode: 401, body: "{\"errors\":[{\"status\":\"401\"}]}"))
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("ESIOS client maps network timeout errors")
  func mapsNetworkTimeout() async {
    let client = PricingClient.esiosLive(
      apiKeyProvider: { "token" },
      fetcher: { _ in
        throw URLError(.timedOut)
      }
    )

    do {
      _ = try await client.fetchDailyPrices(.now, .current)
      Issue.record("Expected network error.")
    } catch let error as PricingClientError {
      #expect(error == .network(String(URLError.Code.timedOut.rawValue)))
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
