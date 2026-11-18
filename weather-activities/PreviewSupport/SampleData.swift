import Foundation

/// Domain fixtures for SwiftUI previews, modelled on real Open-Meteo responses.
nonisolated enum SampleData {
    static let parisFrance = Location(
        id: 2988507, name: "Paris", region: "Île-de-France Region", country: "France",
        latitude: 48.85341, longitude: 2.3488
    )
    static let parisTexas = Location(
        id: 4717560, name: "Paris", region: "Texas", country: "United States",
        latitude: 33.66094, longitude: -95.55551
    )
    static let parisTennessee = Location(
        id: 4647963, name: "Paris", region: "Tennessee", country: "United States",
        latitude: 36.302, longitude: -88.32671
    )
    static let sanFrancisco = Location(
        id: 5391959, name: "San Francisco", region: "California", country: "United States",
        latitude: 37.77493, longitude: -122.41942
    )
    static let chamonix = Location(
        id: 3027301, name: "Chamonix", region: "Auvergne-Rhône-Alpes", country: "France",
        latitude: 45.92375, longitude: 6.86933
    )

    static let parisResults = [parisFrance, parisTexas, parisTennessee]
    static let recentLocations = [sanFrancisco, parisFrance, chamonix]

    /// Coastal: every day has a wave height.
    static let sanFranciscoForecast = week(in: "America/Los_Angeles", [
        (.partlyCloudy, high: 18, low: 12, precipitation: 0, snowfall: 0, wind: 14, waves: 1.6),
        (.clear, high: 19, low: 12, precipitation: 0, snowfall: 0, wind: 10, waves: 1.4),
        (.rain, high: 14, low: 11, precipitation: 12, snowfall: 0, wind: 32, waves: 2.6),
        (.overcast, high: 15, low: 11, precipitation: 0.4, snowfall: 0, wind: 18, waves: 2.1),
        (.clear, high: 20, low: 13, precipitation: 0, snowfall: 0, wind: 12, waves: 0.9),
        (.drizzle, high: 15, low: 11, precipitation: 2.5, snowfall: 0, wind: 22, waves: 1.8),
        (.partlyCloudy, high: 17, low: 12, precipitation: 0, snowfall: 0, wind: 16, waves: 1.2),
    ])

    /// Inland: no wave data at all, so surfing can't be scored.
    static let chamonixForecast = week(in: "Europe/Paris", [
        (.snow, high: -4, low: -11, precipitation: 9, snowfall: 12, wind: 20, waves: nil),
        (.clear, high: -2, low: -12, precipitation: 0, snowfall: 0, wind: 8, waves: nil),
        (.partlyCloudy, high: 1, low: -8, precipitation: 0, snowfall: 0, wind: 12, waves: nil),
        (.snow, high: 0, low: -6, precipitation: 6, snowfall: 8, wind: 25, waves: nil),
        (.fog, high: 2, low: -4, precipitation: 0.2, snowfall: 0, wind: 6, waves: nil),
        (.overcast, high: 3, low: -3, precipitation: 1, snowfall: 1, wind: 15, waves: nil),
        (.snow, high: -1, low: -7, precipitation: 10, snowfall: 15, wind: 30, waves: nil),
    ])

    /// A rainy San Francisco day where indoor sightseeing comes out on top.
    static var rainyDay: DayRecommendation {
        ActivityRecommendationService().recommendation(for: sanFranciscoForecast.days[2])
    }

    private typealias Day = (
        condition: WeatherCondition,
        high: Double,
        low: Double,
        precipitation: Double,
        snowfall: Double,
        wind: Double,
        waves: Double?
    )

    /// Consecutive days starting today, each at midnight in `timeZoneIdentifier`.
    private static func week(in timeZoneIdentifier: String, _ days: [Day]) -> Forecast {
        let timeZone = TimeZone(identifier: timeZoneIdentifier)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: .now)
        return Forecast(
            timeZone: timeZone,
            days: days.enumerated().map { offset, day in
                DailyWeather(
                    date: calendar.date(byAdding: .day, value: offset, to: today)!,
                    condition: day.condition,
                    highC: day.high,
                    lowC: day.low,
                    precipitationMM: day.precipitation,
                    snowfallCM: day.snowfall,
                    windSpeedMaxKmh: day.wind,
                    waveHeightMaxM: day.waves
                )
            }
        )
    }
}
