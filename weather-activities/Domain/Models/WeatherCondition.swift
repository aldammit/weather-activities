import Foundation

/// The day's dominant weather, grouped the way WMO weather codes are.
nonisolated enum WeatherCondition: Hashable, Sendable {
    case clear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm

    var name: LocalizedStringResource {
        switch self {
        case .clear: "Sunny"
        case .partlyCloudy: "Partly cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorm"
        }
    }
}
