import Foundation

/// One day of forecast. Optional measurements are `nil` when the forecast has no data, never zero.
nonisolated struct DailyWeather: Hashable, Sendable {
    /// Start of the day in the forecast location's time zone.
    let date: Date
    let condition: WeatherCondition
    let highC: Double
    let lowC: Double
    let precipitationMM: Double?
    let snowfallCM: Double?
    let windSpeedMaxKmh: Double?
    let waveHeightMaxM: Double?

    var high: Measurement<UnitTemperature> { Measurement(value: highC, unit: .celsius) }
    var low: Measurement<UnitTemperature> { Measurement(value: lowC, unit: .celsius) }
}
