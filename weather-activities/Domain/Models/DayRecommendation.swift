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

    var id: Activity { activity }
}
