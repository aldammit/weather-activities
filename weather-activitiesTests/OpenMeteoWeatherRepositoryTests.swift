import Foundation
import Testing
@testable import weather_activities

/// Covers the repository together with `ForecastMapper`.
struct OpenMeteoWeatherRepositoryTests {
    private func makeRepository(
        forecast: StubTransport.Response = .json(ForecastJSON().body),
        marine: StubTransport.Response = .json(Fixtures.chamonixMarineJSON)
    ) -> (OpenMeteoWeatherRepository, StubTransport) {
        let transport = StubTransport([.forecast: forecast, .marine: marine])
        return (OpenMeteoWeatherRepository(client: OpenMeteoClient(transport: transport)), transport)
    }

    // MARK: Mapping

    @Test func datesAreMidnightsInTheCityTimeZone() async throws {
        let (repository, _) = makeRepository(forecast: .json(Fixtures.parisTexasForecastJSON))

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        let chicago = try #require(TimeZone(identifier: "America/Chicago"))
        #expect(forecast.timeZone == chicago)
        #expect(forecast.days.count == 7)
        // 2026-11-17T06:00:00Z: midnight in Chicago, which is UTC−6 in November.
        #expect(forecast.days.first?.date == Date(timeIntervalSince1970: 1_794_895_200))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = chicago
        for (offset, day) in forecast.days.enumerated() {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day.date)
            #expect(components == DateComponents(year: 2026, month: 11, day: 17 + offset, hour: 0, minute: 0))
        }
    }

    @Test func mapsLiveValues() async throws {
        let (repository, _) = makeRepository(forecast: .json(Fixtures.parisTexasForecastJSON))

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        let first = try #require(forecast.days.first)
        #expect(first.condition == .clear)
        #expect(first.highC == 16.8)
        #expect(first.lowC == 1.6)
        #expect(first.precipitationMM == 0)
        #expect(first.snowfallCM == 0)
        #expect(first.windSpeedMaxKmh == 12.0)
        #expect(forecast.days.map(\.condition) == [.clear, .partlyCloudy, .overcast, .overcast, .drizzle, .drizzle, .partlyCloudy])
    }

    @Test func nullValuesStayNil() async throws {
        var json = ForecastJSON()
        json.snowfallSum[1] = nil
        json.windSpeedMax[2] = nil
        let (repository, _) = makeRepository(forecast: .json(json.body))

        let days = try await repository.forecast(for: Fixtures.parisTexas).days

        #expect(days[0].snowfallCM == 0)
        #expect(days[1].snowfallCM == nil)
        #expect(days[2].windSpeedMaxKmh == nil)
    }

    @Test func incompleteDaysAreSkipped() async throws {
        var json = ForecastJSON()
        json.weatherCode[1] = nil
        json.weatherCode[2] = 42 // Not a WMO code Open-Meteo documents.
        json.temperatureMax[3] = nil
        json.temperatureMin[4] = nil
        let (repository, _) = makeRepository(forecast: .json(json.body))

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        let dayStyle = Date.ISO8601FormatStyle(timeZone: forecast.timeZone).year().month().day()
        #expect(forecast.days.map { dayStyle.format($0.date) } == ["2026-11-17", "2026-11-22", "2026-11-23"])
    }

    @Test func noCompleteDaysGivesAnEmptyForecast() async throws {
        var json = ForecastJSON()
        json.weatherCode = Array(repeating: nil, count: 7)
        let (repository, _) = makeRepository(forecast: .json(json.body))

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        #expect(forecast.days.isEmpty)
    }

    enum Corruption: CaseIterable {
        case shortColumn, longColumn, unknownTimeZone, unparseableDate

        func apply(to json: inout ForecastJSON) {
            switch self {
            case .shortColumn: json.precipitationSum.removeLast()
            case .longColumn: json.weatherCode.append(0)
            case .unknownTimeZone: json.timezone = "Mars/Olympus_Mons"
            case .unparseableDate: json.time[3] = "20 Nov 2026"
            }
        }
    }

    @Test(arguments: Corruption.allCases)
    func inconsistentForecastIsMalformed(corruption: Corruption) async {
        var json = ForecastJSON()
        corruption.apply(to: &json)
        let (repository, _) = makeRepository(forecast: .json(json.body))

        await #expect(throws: RepositoryError.malformedForecast) {
            try await repository.forecast(for: Fixtures.parisTexas)
        }
    }

    @Test func forecastFailureIsThrown() async {
        let (repository, _) = makeRepository(forecast: .json("{}", status: 503))

        await #expect(throws: RepositoryError.httpStatus(503)) {
            try await repository.forecast(for: Fixtures.parisTexas)
        }
    }

    // MARK: Marine

    @Test func liveWaveHeightsAreMerged() async throws {
        let (repository, _) = makeRepository(
            forecast: .json(Fixtures.sanFranciscoForecastJSON),
            marine: .json(Fixtures.sanFranciscoMarineJSON)
        )

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        #expect(forecast.days.map(\.waveHeightMaxM) == [2.32, 2.50, 2.62, 2.06, 1.34, 1.66, 1.60])
    }

    @Test func waveHeightsAreMatchedByDate() async throws {
        let marine = MarineJSON(time: ["2026-11-19", "2026-11-18", "2026-11-30"], waveHeightMax: [2.6, 1.5, 9.9])
        let (repository, _) = makeRepository(marine: .json(marine.body))

        let days = try await repository.forecast(for: Fixtures.parisTexas).days

        #expect(days.map(\.waveHeightMaxM) == [nil, 1.5, 2.6, nil, nil, nil, nil])
    }

    @Test(arguments: [
        StubTransport.Response.json(Fixtures.chamonixMarineJSON),
        .json("{}", status: 400),
        .failure(URLError(.timedOut)),
        .json("{\"daily\":{}}"),
        .json(MarineJSON(time: ["2026-11-17", "2026-11-18"], waveHeightMax: [1.2]).body),
    ])
    func unusableMarineDataMeansNoWaves(marine: StubTransport.Response) async throws {
        let (repository, _) = makeRepository(marine: marine)

        let forecast = try await repository.forecast(for: Fixtures.parisTexas)

        #expect(forecast.days.count == 7)
        #expect(forecast.days.allSatisfy { $0.waveHeightMaxM == nil })
    }

    @Test func cancelledMarineRequestCancelsTheForecast() async {
        let (repository, _) = makeRepository(marine: .failure(URLError(.cancelled)))

        await #expect(throws: CancellationError.self) {
            try await repository.forecast(for: Fixtures.parisTexas)
        }
    }

    // MARK: Requests

    @Test func requestsSevenDaysInTheCityTimeZone() async throws {
        let (repository, transport) = makeRepository()

        _ = try await repository.forecast(for: Fixtures.parisTexas)

        let forecastURL = try #require(transport.requests(to: .forecast).first?.url)
        let forecastItems = try #require(URLComponents(url: forecastURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(forecastItems == [
            URLQueryItem(name: "latitude", value: "33.66094"),
            URLQueryItem(name: "longitude", value: "-95.55551"),
            URLQueryItem(
                name: "daily",
                value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max"
            ),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ])
        let marineURL = try #require(transport.requests(to: .marine).first?.url)
        let marineItems = try #require(URLComponents(url: marineURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(marineItems.contains(URLQueryItem(name: "daily", value: "wave_height_max")))
        #expect(marineItems.contains(URLQueryItem(name: "timezone", value: "auto")))
    }
}
