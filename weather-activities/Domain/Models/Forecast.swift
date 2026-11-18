import Foundation

/// Daily forecast for one location, with dates in that location's time zone.
nonisolated struct Forecast: Hashable, Sendable {
    let timeZone: TimeZone
    let days: [DailyWeather]
}
