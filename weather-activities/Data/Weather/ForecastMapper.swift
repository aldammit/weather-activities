import Foundation

/// Turns Open-Meteo forecast and marine responses into a `Forecast`.
nonisolated enum ForecastMapper {
    /// Days missing a weather code, a known WMO code, a high or a low are skipped.
    /// Wave heights are matched by date; a missing or malformed marine response leaves them `nil`.
    ///
    /// - Throws: `RepositoryError.malformedForecast` for an unknown time zone, uneven arrays or an unparseable date.
    static func map(forecast: ForecastResponseDTO, marine: MarineResponseDTO?) throws -> Forecast {
        guard let timeZone = TimeZone(identifier: forecast.timezone) else {
            throw RepositoryError.malformedForecast
        }
        let daily = forecast.daily
        let columnLengths = [
            daily.weatherCode.count,
            daily.temperatureMax.count,
            daily.temperatureMin.count,
            daily.precipitationSum.count,
            daily.snowfallSum.count,
            daily.windSpeedMax.count,
        ]
        guard columnLengths.allSatisfy({ $0 == daily.time.count }) else {
            throw RepositoryError.malformedForecast
        }

        let dateStyle = Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day()
        let waveHeights = waveHeightsByDate(marine)

        let days = try daily.time.indices.compactMap { index -> DailyWeather? in
            let dateString = daily.time[index]
            guard let date = try? dateStyle.parse(dateString) else {
                throw RepositoryError.malformedForecast
            }
            guard let code = daily.weatherCode[index],
                  let condition = WeatherCondition(wmoCode: code),
                  let high = daily.temperatureMax[index],
                  let low = daily.temperatureMin[index]
            else { return nil }
            return DailyWeather(
                date: date,
                condition: condition,
                highC: high,
                lowC: low,
                precipitationMM: daily.precipitationSum[index],
                snowfallCM: daily.snowfallSum[index],
                windSpeedMaxKmh: daily.windSpeedMax[index],
                waveHeightMaxM: waveHeights[dateString]
            )
        }
        return Forecast(timeZone: timeZone, days: days)
    }

    /// Non-null wave heights keyed by `yyyy-MM-dd`; empty when the marine arrays are missing or uneven.
    private static func waveHeightsByDate(_ marine: MarineResponseDTO?) -> [String: Double] {
        guard let daily = marine?.daily, daily.time.count == daily.waveHeightMax.count else { return [:] }
        let pairs = zip(daily.time, daily.waveHeightMax).compactMap { date, height in
            height.map { (date, $0) }
        }
        return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    }
}
