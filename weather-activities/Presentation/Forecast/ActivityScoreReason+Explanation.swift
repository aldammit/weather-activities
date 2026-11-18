import Foundation

extension ActivityScoreReason {
    var explanation: String {
        switch self {
        case .skiing(let highC, let snowfallCM):
            return String(localized: "A high of \(temperature(highC)) with \(length(snowfallCM, in: .centimeters)) of fresh snow.")
        case .skiingTooWarm(let highC):
            return String(localized: "A high of \(temperature(highC)) is too warm for skiing.")
        case .surfing(let waveHeightM, let windKmh, let highC):
            return String(localized: "Waves up to \(length(waveHeightM, in: .meters)), winds up to \(wind(windKmh)), and a high of \(temperature(highC)).")
        case .surfingWavesOutOfRange(let waveHeightM):
            return String(localized: "The maximum wave height of \(length(waveHeightM, in: .meters)) is outside the range used for surfing.")
        case .surfingThunderstorm:
            return String(localized: "Thunderstorms rule out surfing.")
        case .outdoorSightseeing(let highC, let precipitationMM, let windKmh, let penalty):
            let conditions = String(localized: "A high of \(temperature(highC)), \(length(precipitationMM, in: .millimeters)) of precipitation, and winds up to \(wind(windKmh)).")
            switch penalty {
            case .fog:
                return String(localized: "\(conditions) Fog lowers the score.")
            case .thunderstorm:
                return String(localized: "\(conditions) Thunderstorms lower the score.")
            case nil:
                return conditions
            }
        case .indoorSightseeing(let outdoorScore):
            return String(localized: "Outdoor sightseeing scored \(outdoorScore.formatted(.score)). Lower outdoor scores favor indoor plans.")
        case .missingData(let inputs):
            let names = inputs.map(\.displayName).formatted(.list(type: .and))
            return String(localized: "Forecast data is unavailable for \(names).")
        }
    }

    private func temperature(_ celsius: Double) -> String {
        Measurement(value: celsius, unit: UnitTemperature.celsius).formatted(.temperature)
    }

    private func length(_ value: Double, in unit: UnitLength) -> String {
        Measurement(value: value, unit: unit)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }

    private func wind(_ kilometersPerHour: Double) -> String {
        Measurement(value: kilometersPerHour, unit: UnitSpeed.kilometersPerHour)
            .formatted(.measurement(width: .wide, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }
}

private extension ActivityScoreReason.Input {
    var displayName: String {
        switch self {
        case .precipitation: String(localized: "precipitation")
        case .snowfall: String(localized: "snowfall")
        case .windSpeed: String(localized: "wind speed")
        case .waveHeight: String(localized: "wave height")
        }
    }
}
