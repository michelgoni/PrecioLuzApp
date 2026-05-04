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
  static let liveValue = PricingClient.esiosLive()

  static let testValue = PricingClient { day, timeZone in
    StubPricingModel.makeDailyPrices(for: day, timeZone: timeZone)
  }
}

enum PricingClientError: Error, Equatable, Sendable {
  case emptyResponse
  case invalidDate(String)
  case invalidRequest
  case invalidResponse
  case missingAPIKey
  case missingPVPCValues
  case network(String)
  case requestFailed(statusCode: Int, body: String?)
}

extension PricingClient {
  static func esiosLive(
    apiKeyProvider: @escaping @Sendable () -> String? = {
      LocalAPIKeyProvider.apiKey()
    },
    fetcher: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = { request in
      try await URLSession.shared.data(for: request)
    }
  ) -> PricingClient {
    PricingClient { day, timeZone in
      try await EsiosPricingAPI.fetchDailyPrices(
        for: day,
        timeZone: timeZone,
        apiKeyProvider: apiKeyProvider,
        fetcher: fetcher
      )
    }
  }
}

enum LocalAPIKeyProvider {
  private static let bundledEnvResourceName = "PrecioLuzLocal"
  private static let bundledEnvResourceExtension = "env"

  static func apiKey(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    readFile: (String) -> String? = { try? String(contentsOfFile: $0, encoding: .utf8) },
    bundledEnvFileContents: () -> String? = {
      guard let url = Bundle.main.url(
        forResource: bundledEnvResourceName,
        withExtension: bundledEnvResourceExtension
      ) else {
        return nil
      }
      return try? String(contentsOf: url, encoding: .utf8)
    }
  ) -> String? {
    if let apiKey = normalizedValue(environment["REE_API_KEY"]) {
      return apiKey
    }
    if let envFilePath = normalizedValue(environment["PRECIOLUZ_ENV_FILE"]),
       let apiKey = apiKey(fromEnvFileContents: readFile(envFilePath) ?? "") {
      return apiKey
    }
    return apiKey(fromEnvFileContents: bundledEnvFileContents() ?? "")
  }

  static func apiKey(fromEnvFileContents contents: String) -> String? {
    contents
      .split(whereSeparator: \.isNewline)
      .compactMap { line -> String? in
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.hasPrefix("#") else {
          return nil
        }
        let parts = trimmedLine.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts[0].trimmingCharacters(in: .whitespacesAndNewlines) == "REE_API_KEY" else {
          return nil
        }
        return normalizedValue(String(parts[1]))
      }
      .first ?? nil
  }

  private static func normalizedValue(_ value: String?) -> String? {
    let normalizedValue = value?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    guard let normalizedValue, !normalizedValue.isEmpty else {
      return nil
    }
    return normalizedValue
  }
}

private enum EsiosPricingAPI {
  private static let endpoint = URL(string: "https://api.esios.ree.es/indicators/1001")!
  private static let peninsularGeoID = "8741"
  private static let unitScaleEURPerMWhToEURPerKWh = 1_000.0

  static func fetchDailyPrices(
    for day: Date,
    timeZone: TimeZone,
    apiKeyProvider: @escaping @Sendable () -> String?,
    fetcher: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
  ) async throws -> [PricingClient.HourPrice] {
    guard let apiKey = apiKeyProvider() else {
      throw PricingClientError.missingAPIKey
    }
    let request = try makeRequest(for: day, timeZone: timeZone, apiKey: apiKey)

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await fetcher(request)
    } catch {
      throw mapNetworkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw PricingClientError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
      let body = String(data: data, encoding: .utf8)
      throw PricingClientError.requestFailed(statusCode: httpResponse.statusCode, body: body)
    }

    let decoder = JSONDecoder()
    let payload = try decoder.decode(ResponsePayload.self, from: data)
    let filteredValues = payload.indicator.values.filter { $0.geoID == Int(peninsularGeoID) }
    let values = filteredValues.isEmpty ? payload.indicator.values : filteredValues
    guard !values.isEmpty else {
      throw PricingClientError.missingPVPCValues
    }
    return try mapSeriesValuesToHourlyPrices(values, day: day, timeZone: timeZone)
  }

  private static func makeRequest(for day: Date, timeZone: TimeZone, apiKey: String) throws -> URLRequest {
    let url = try makeURL(for: day, timeZone: timeZone)
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 15
    request.setValue(
      "application/json; application/vnd.esios-api-v1+json",
      forHTTPHeaderField: "Accept"
    )
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    return request
  }

  private static func makeURL(for day: Date, timeZone: TimeZone) throws -> URL {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let startOfDay = calendar.startOfDay(for: day)
    let endOfDay = calendar.date(byAdding: DateComponents(day: 1, minute: -1), to: startOfDay) ?? startOfDay

    var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
    let queryItems: [URLQueryItem] = [
      .init(name: "start_date", value: DateFormatting.apiDate(startOfDay, timeZone: timeZone)),
      .init(name: "end_date", value: DateFormatting.apiDate(endOfDay, timeZone: timeZone)),
      .init(name: "time_trunc", value: "hour"),
      .init(name: "geo_ids[]", value: peninsularGeoID),
    ]
    components?.queryItems = queryItems

    guard let url = components?.url else {
      throw PricingClientError.invalidRequest
    }
    return url
  }

  private static func mapSeriesValuesToHourlyPrices(
    _ values: [IndicatorValue],
    day: Date,
    timeZone: TimeZone
  ) throws -> [PricingClient.HourPrice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let startOfDay = calendar.startOfDay(for: day)
    let nextDayStart = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

    let parsedValues = try values.map { value in
      guard let date = DateFormatting.parseResponseDate(value.datetime) else {
        throw PricingClientError.invalidDate(value.datetime)
      }
      return PricingClient.HourPrice(
        date: date,
        eurPerKWh: value.value / unitScaleEURPerMWhToEURPerKWh
      )
    }

    let deduplicated = Dictionary(grouping: parsedValues, by: \.date)
      .compactMap { $0.value.first }

    return deduplicated
      .filter { hourlyPrice in
        hourlyPrice.date >= startOfDay && hourlyPrice.date < nextDayStart
      }
      .sorted { $0.date < $1.date }
  }

  private enum DateFormatting {
    static func apiDate(_ date: Date, timeZone: TimeZone) -> String {
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = timeZone
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
      return formatter.string(from: date)
    }

    static func parseResponseDate(_ value: String) -> Date? {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter.date(from: value)
    }
  }

  private static func mapNetworkError(_ error: Error) -> PricingClientError {
    if let urlError = error as? URLError {
      return .network(urlError.code.rawValue.description)
    }
    return .network(String(describing: error))
  }

  private struct ResponsePayload: Decodable {
    var indicator: Indicator
  }

  private struct Indicator: Decodable {
    var values: [IndicatorValue]
  }

  private struct IndicatorValue: Decodable {
    var datetime: String
    var geoID: Int?
    var value: Double

    enum CodingKeys: String, CodingKey {
      case datetime
      case geoID = "geo_id"
      case value
    }
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
