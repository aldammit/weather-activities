import Foundation

/// Response of Open-Meteo's `/v1/forecast` endpoint with daily variables.
nonisolated struct ForecastResponseDTO: Decodable, Sendable {
    /// IANA identifier, resolved from the coordinates because the request uses `timezone=auto`.
    let timezone: String
    let daily: Daily

    /// Parallel arrays, one entry per `time` element. Any value can be `null`.
    nonisolated struct Daily: Decodable, Sendable {
        /// Local dates, `yyyy-MM-dd`.
        let time: [String]
        let weatherCode: [Int?]
        let temperatureMax: [Double?]
        let temperatureMin: [Double?]
        let precipitationSum: [Double?]
        let snowfallSum: [Double?]
        let windSpeedMax: [Double?]

        nonisolated enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationSum = "precipitation_sum"
            case snowfallSum = "snowfall_sum"
            case windSpeedMax = "wind_speed_10m_max"
        }
    }
}
