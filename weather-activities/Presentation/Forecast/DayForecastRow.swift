import SwiftUI

struct DayForecastRow: View {
    let day: DayRecommendation

    /// The forecast location's time zone, so the spoken date matches the place, not the device.
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DaySummary(weather: day.weather)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAddTraits(.isHeader)
            Divider()
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                ForEach(day.rankedScores) { score in
                    ActivityRankingRow(score: score, isBest: score.activity == day.best?.activity)
                }
            }
        }
        .padding(12)
        .cardSurface()
        .accessibilityElement(children: .contain)
    }

    /// "Tuesday, November 17, Clear, high 18°, low 12°", dated in the forecast location's time zone.
    private var accessibilitySummary: Text {
        let weather = day.weather
        let dateStyle = Date.FormatStyle(timeZone: timeZone).weekday(.wide).day().month(.wide)
        return Text(
            "\(weather.date, format: dateStyle), \(Text(weather.condition.name)), high \(weather.high, format: .temperature), low \(weather.low, format: .temperature)"
        )
    }
}

#Preview("Rainy day") {
    DayForecastRow(day: SampleData.rainyDay)
        .environment(\.timeZone, SampleData.sanFranciscoForecast.timeZone)
        .padding()
        .frame(maxHeight: .infinity)
        .background { SkyBackground() }
}
