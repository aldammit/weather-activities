import Foundation

/// Scores every activity for every forecast day and ranks them.
///
/// Scores are in 0…1. An activity scores `nil` when the day lacks a measurement it depends on.
nonisolated struct ActivityRecommendationService: Sendable {
    func recommendations(for forecast: Forecast) -> [DayRecommendation] {
        forecast.days.map(recommendation(for:))
    }

    func recommendation(for day: DailyWeather) -> DayRecommendation {
        let outdoor = outdoorSightseeing(on: day)
        let scores = Activity.allCases.map { activity in
            switch activity {
            case .surfing: surfing(on: day)
            case .outdoorSightseeing: outdoor
            case .indoorSightseeing: indoorSightseeing(outdoor: outdoor)
            case .skiing: skiing(on: day)
            }
        }
        return DayRecommendation(weather: day, rankedScores: ranked(scores))
    }

    private func skiing(on day: DailyWeather) -> ActivityScore {
        guard let snowfall = day.snowfallCM else {
            return ActivityScore(activity: .skiing, score: nil, reason: .missingData([.snowfall]))
        }
        let cold = ramp(day.highC, from: 8, to: 0)
        let freshSnow = ramp(snowfall, from: 0, to: 10)
        let reason: ActivityScoreReason = cold == 0
            ? .skiingTooWarm(highC: day.highC)
            : .skiing(highC: day.highC, snowfallCM: snowfall)
        return ActivityScore(activity: .skiing, score: cold * (0.3 + 0.7 * freshSnow), reason: reason)
    }

    private func surfing(on day: DailyWeather) -> ActivityScore {
        guard let waveHeight = day.waveHeightMaxM, let wind = day.windSpeedMaxKmh else {
            var missing: [ActivityScoreReason.Input] = []
            if day.waveHeightMaxM == nil { missing.append(.waveHeight) }
            if day.windSpeedMaxKmh == nil { missing.append(.windSpeed) }
            return ActivityScore(activity: .surfing, score: nil, reason: .missingData(missing))
        }
        guard day.condition != .thunderstorm else {
            return ActivityScore(activity: .surfing, score: 0, reason: .surfingThunderstorm)
        }
        // Ideal from 1 to 2.5 m; flat at 0.3 m or less, too big at 3.5 m or more.
        let waves = min(ramp(waveHeight, from: 0.3, to: 1), ramp(waveHeight, from: 3.5, to: 2.5))
        let calm = ramp(wind, from: 40, to: 15)
        let warm = ramp(day.highC, from: 8, to: 20)
        let reason: ActivityScoreReason = waves == 0
            ? .surfingWavesOutOfRange(waveHeightM: waveHeight)
            : .surfing(waveHeightM: waveHeight, windKmh: wind, highC: day.highC)
        return ActivityScore(activity: .surfing, score: waves * (0.6 + 0.4 * calm) * (0.5 + 0.5 * warm), reason: reason)
    }

    private func outdoorSightseeing(on day: DailyWeather) -> ActivityScore {
        guard let precipitation = day.precipitationMM, let wind = day.windSpeedMaxKmh else {
            var missing: [ActivityScoreReason.Input] = []
            if day.precipitationMM == nil { missing.append(.precipitation) }
            if day.windSpeedMaxKmh == nil { missing.append(.windSpeed) }
            return ActivityScore(activity: .outdoorSightseeing, score: nil, reason: .missingData(missing))
        }
        // Comfortable from 16 to 26 °C; unpleasant at 5 °C or less and 34 °C or more.
        let comfort = min(ramp(day.highC, from: 5, to: 16), ramp(day.highC, from: 34, to: 26))
        let dry = ramp(precipitation, from: 10, to: 0)
        let calm = ramp(wind, from: 50, to: 20)
        let score = 0.45 * comfort + 0.4 * dry + 0.15 * calm
        let (multiplier, penalty): (Double, ActivityScoreReason.OutdoorPenalty?) = switch day.condition {
        case .fog: (0.8, .fog)
        case .thunderstorm: (0.3, .thunderstorm)
        default: (1, nil)
        }
        let reason = ActivityScoreReason.outdoorSightseeing(
            highC: day.highC, precipitationMM: precipitation, windKmh: wind, penalty: penalty
        )
        return ActivityScore(activity: .outdoorSightseeing, score: score * multiplier, reason: reason)
    }

    /// The worse it is outside, the better indoors: from 0.35 on a perfect day to 0.95 on the worst.
    private func indoorSightseeing(outdoor: ActivityScore) -> ActivityScore {
        guard let outdoorScore = outdoor.score else {
            return ActivityScore(activity: .indoorSightseeing, score: nil, reason: outdoor.reason)
        }
        return ActivityScore(
            activity: .indoorSightseeing,
            score: 0.35 + 0.6 * (1 - outdoorScore),
            reason: .indoorSightseeing(outdoorScore: outdoorScore)
        )
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
