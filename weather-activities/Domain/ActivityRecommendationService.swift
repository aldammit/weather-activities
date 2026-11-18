import Foundation

/// Scores every activity for every forecast day and ranks them.
///
/// Scores are in 0…1. An activity scores `nil` when the day lacks a measurement it depends on.
nonisolated struct ActivityRecommendationService: Sendable {
    func recommendations(for forecast: Forecast) -> [DayRecommendation] {
        forecast.days.map(recommendation(for:))
    }

    func recommendation(for day: DailyWeather) -> DayRecommendation {
        let scores = Activity.allCases.map { activity in
            ActivityScore(activity: activity, score: score(for: activity, on: day))
        }
        return DayRecommendation(weather: day, rankedScores: ranked(scores))
    }

    private func score(for activity: Activity, on day: DailyWeather) -> Double? {
        switch activity {
        case .surfing: surfingScore(day)
        case .outdoorSightseeing: outdoorSightseeingScore(day)
        case .indoorSightseeing: indoorSightseeingScore(day)
        case .skiing: skiingScore(day)
        }
    }

    private func skiingScore(_ day: DailyWeather) -> Double? {
        guard let snowfall = day.snowfallCM else { return nil }
        let cold = ramp(day.highC, from: 8, to: 0)
        let freshSnow = ramp(snowfall, from: 0, to: 10)
        return cold * (0.3 + 0.7 * freshSnow)
    }

    private func surfingScore(_ day: DailyWeather) -> Double? {
        guard let waveHeight = day.waveHeightMaxM, let wind = day.windSpeedMaxKmh else { return nil }
        guard day.condition != .thunderstorm else { return 0 }
        // Ideal from 1 to 2.5 m; flat at 0.3 m or less, too big at 3.5 m or more.
        let waves = min(ramp(waveHeight, from: 0.3, to: 1), ramp(waveHeight, from: 3.5, to: 2.5))
        let calm = ramp(wind, from: 40, to: 15)
        let warm = ramp(day.highC, from: 8, to: 20)
        return waves * (0.6 + 0.4 * calm) * (0.5 + 0.5 * warm)
    }

    private func outdoorSightseeingScore(_ day: DailyWeather) -> Double? {
        guard let precipitation = day.precipitationMM, let wind = day.windSpeedMaxKmh else { return nil }
        // Comfortable from 16 to 26 °C; unpleasant at 5 °C or less and 34 °C or more.
        let comfort = min(ramp(day.highC, from: 5, to: 16), ramp(day.highC, from: 34, to: 26))
        let dry = ramp(precipitation, from: 10, to: 0)
        let calm = ramp(wind, from: 50, to: 20)
        let score = 0.45 * comfort + 0.4 * dry + 0.15 * calm
        switch day.condition {
        case .fog: return score * 0.8
        case .thunderstorm: return score * 0.3
        default: return score
        }
    }

    /// The worse it is outside, the better indoors: from 0.35 on a perfect day to 0.95 on the worst.
    private func indoorSightseeingScore(_ day: DailyWeather) -> Double? {
        outdoorSightseeingScore(day).map { 0.35 + 0.6 * (1 - $0) }
    }

    /// Best first, unscored activities last. `sorted(by:)` is stable, so equal scores keep `Activity.allCases` order.
    private func ranked(_ scores: [ActivityScore]) -> [ActivityScore] {
        scores.sorted { ($0.score ?? -1) > ($1.score ?? -1) }
    }

    /// 0 at `start`, 1 at `end`, linear in between and clamped outside. `end` may be below `start`.
    private func ramp(_ value: Double, from start: Double, to end: Double) -> Double {
        min(max((value - start) / (end - start), 0), 1)
    }
}
