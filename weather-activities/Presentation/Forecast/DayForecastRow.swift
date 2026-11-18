import SwiftUI

struct DayForecastRow: View {
    let day: DayRecommendation

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The forecast location's time zone, so the spoken date matches the place, not the device.
    @Environment(\.timeZone) private var timeZone
    @ScaledMetric(relativeTo: .headline) private var summaryWidth = 92.0

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let layout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        let weather = day.weather

        layout {
            DaySummary(weather: weather)
                .frame(width: isAccessibilitySize ? nil : summaryWidth)
            Divider()
            ActivityTiles(scores: day.rankedScores, bestActivity: day.best?.activity, isGrid: isAccessibilitySize)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(rankingDescription)
    }

    /// "Tuesday, November 17, Clear, high 18°, low 12°", dated in the forecast location's time zone.
    private var accessibilitySummary: Text {
        let weather = day.weather
        let dateStyle = Date.FormatStyle(timeZone: timeZone).weekday(.wide).day().month(.wide)
        return Text(
            "\(weather.date, format: dateStyle), \(Text(weather.condition.name)), high \(weather.high, format: .temperature), low \(weather.low, format: .temperature)"
        )
    }

    /// "Surfing 92%, Outdoor sightseeing 78%, …", best first.
    private var rankingDescription: String {
        day.rankedScores
            .map { activityScore in
                let name = String(localized: activityScore.activity.name)
                guard let score = activityScore.score else {
                    return String(
                        localized: "\(name) no data",
                        comment: "VoiceOver, for an activity that can't be scored. The variable is the activity name."
                    )
                }
                return String(
                    localized: "\(name) \(score.formatted(.score))",
                    comment: "VoiceOver activity score. The first variable is the activity name, the second its percentage."
                )
            }
            .formatted(.list(type: .and))
    }
}

/// The day's activities, best first: one row normally, a 2×2 grid at accessibility sizes.
private struct ActivityTiles: View {
    let scores: [ActivityScore]
    let bestActivity: Activity?
    let isGrid: Bool

    var body: some View {
        if isGrid {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                tiles
            }
            .padding(.top, 8)
        } else {
            HStack(spacing: 8) {
                tiles
            }
        }
    }

    private var tiles: some View {
        ForEach(scores) { activityScore in
            ActivityTile(
                activity: activityScore.activity,
                score: activityScore.score,
                isBest: activityScore.activity == bestActivity
            )
        }
    }
}

#Preview("Rainy day") {
    DayForecastRow(day: SampleData.rainyDay)
        .environment(\.timeZone, SampleData.sanFranciscoForecast.timeZone)
        .padding()
        .frame(maxHeight: .infinity)
        .background { SkyBackground() }
}
