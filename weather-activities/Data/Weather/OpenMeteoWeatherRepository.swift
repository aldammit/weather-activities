import Foundation

/// Fetches the daily forecast and marine wave heights in parallel.
nonisolated struct OpenMeteoWeatherRepository: WeatherRepository {
    let client: OpenMeteoClient

    func forecast(for location: Location) async throws -> Forecast {
        async let forecastResponse: ForecastResponseDTO = client.get(Self.forecastURL(for: location))
        async let marineResponse = Self.marineIfAvailable(for: location, using: client)

        return try ForecastMapper.map(forecast: await forecastResponse, marine: await marineResponse)
    }

    /// Wave data is optional: any failure other than cancellation means no waves.
    private static func marineIfAvailable(
        for location: Location,
        using client: OpenMeteoClient
    ) async throws -> MarineResponseDTO? {
        do {
            return try await client.get(marineURL(for: location))
        } catch let error as CancellationError {
            throw error
        } catch {
            return nil
        }
    }

    private static func forecastURL(for location: Location) -> URL {
        url(
            "https://api.open-meteo.com/v1/forecast",
            for: location,
            daily: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max"
        )
    }

    private static func marineURL(for location: Location) -> URL {
        url("https://marine-api.open-meteo.com/v1/marine", for: location, daily: "wave_height_max")
    }

    private static func url(_ endpoint: String, for location: Location, daily variables: String) -> URL {
        URL(string: endpoint)!.appending(queryItems: [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "daily", value: variables),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ])
    }
}
