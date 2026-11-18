import Foundation

/// A day's weather with every activity scored for it.
nonisolated struct DayRecommendation: Identifiable, Hashable, Sendable {
    let weather: DailyWeather
    /// Every activity, best first. Activities without enough data come last.
    let rankedScores: [ActivityScore]

    var id: Date { weather.date }

    /// The top-ranked activity, if any activity could be scored.
    var best: ActivityScore? {
        guard let first = rankedScores.first, first.score != nil else { return nil }
        return first
    }
}

nonisolated struct ActivityScore: Identifiable, Hashable, Sendable {
    let activity: Activity
    /// Suitability from 0 (unsuitable) to 1 (ideal), or `nil` when the forecast lacks the data to judge.
    let score: Double?
    let reason: ActivityScoreReason

    var id: Activity { activity }
}

/// Forecast evidence behind an activity's score, expressed in the same units as DailyWeather.
nonisolated enum ActivityScoreReason: Hashable, Sendable {
    nonisolated enum Input: Hashable, Sendable {
        case precipitation
        case snowfall
        case windSpeed
        case waveHeight
    }

    nonisolated enum OutdoorPenalty: Hashable, Sendable {
        case fog
        case thunderstorm
    }

    case skiing(highC: Double, snowfallCM: Double)
    case skiingTooWarm(highC: Double)
    case surfing(waveHeightM: Double, windKmh: Double, highC: Double)
    case surfingWavesOutOfRange(waveHeightM: Double)
    case surfingThunderstorm
    case outdoorSightseeing(highC: Double, precipitationMM: Double, windKmh: Double, penalty: OutdoorPenalty?)
    case indoorSightseeing(outdoorScore: Double)
    case missingData([Input])
}
