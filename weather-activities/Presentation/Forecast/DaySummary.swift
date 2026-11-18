import SwiftUI

struct DaySummary: View {
    let weather: DailyWeather

    /// The forecast location's time zone, so weekdays match the place, not the device.
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        let dateStyle = Date.FormatStyle(timeZone: timeZone)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(weather.date, format: dateStyle.weekday(.abbreviated))
                        .font(.headline)
                        .foregroundStyle(Color(.ink))
                    Text(weather.date, format: dateStyle.day().month(.abbreviated))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: weather.condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.title2)
            }
            Text("\(weather.high, format: .temperature) / \(weather.low, format: .temperature)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(Color(.ink))
        }
    }
}

#Preview {
    DaySummary(weather: SampleData.rainyDay.weather)
        .environment(\.timeZone, SampleData.sanFranciscoForecast.timeZone)
        .frame(width: 96)
        .padding()
}
