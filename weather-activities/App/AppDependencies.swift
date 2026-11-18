import Foundation

/// Everything the screens need, built once at launch and passed down through initializers.
struct AppDependencies {
    let geocoding: any GeocodingRepository
    let weather: any WeatherRepository
    let recents: RecentLocationsStore

    static func live() -> AppDependencies {
        let client = OpenMeteoClient(transport: URLSession.shared)
        return AppDependencies(
            geocoding: OpenMeteoGeocodingRepository(client: client),
            weather: OpenMeteoWeatherRepository(client: client),
            recents: RecentLocationsStore(defaults: .standard)
        )
    }
}
