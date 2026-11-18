import Foundation

/// Answers every search with the same result.
nonisolated struct StubGeocodingRepository: GeocodingRepository {
    var result: Result<[Location], RepositoryError>

    func searchLocations(named query: String) async throws -> [Location] {
        try result.get()
    }
}

/// Answers every forecast request with the same result. With a `nil` result, requests never finish.
nonisolated struct StubWeatherRepository: WeatherRepository {
    var result: Result<Forecast, RepositoryError>?

    func forecast(for location: Location) async throws -> Forecast {
        guard let result else {
            try await Task.sleep(for: .seconds(24 * 60 * 60))
            throw CancellationError()
        }
        return try result.get()
    }
}

extension AppDependencies {
    static func preview(
        geocoding: Result<[Location], RepositoryError> = .success(SampleData.parisResults),
        weather: Result<Forecast, RepositoryError>? = .success(SampleData.sanFranciscoForecast)
    ) -> AppDependencies {
        AppDependencies(
            geocoding: StubGeocodingRepository(result: geocoding),
            weather: StubWeatherRepository(result: weather),
            recents: .preview
        )
    }
}

extension RecentLocationsStore {
    /// A separate defaults suite holding `SampleData.recentLocations`.
    static var preview: RecentLocationsStore {
        let store = RecentLocationsStore(defaults: UserDefaults(suiteName: "preview")!)
        for location in SampleData.recentLocations.reversed() {
            store.record(location)
        }
        return store
    }
}

extension SearchViewModel {
    static func preview(query: String = "", state: SearchState = .idle) -> SearchViewModel {
        let dependencies = AppDependencies.preview()
        return SearchViewModel(geocoding: dependencies.geocoding, recents: dependencies.recents, query: query, state: state)
    }
}

extension ForecastViewModel {
    /// Already loaded with `forecast`; refreshing returns the same forecast.
    static func preview(location: Location, forecast: Forecast, refresh: RefreshStatus = .idle) -> ForecastViewModel {
        let days = ActivityRecommendationService().recommendations(for: forecast)
        let content = ForecastContent(timeZone: forecast.timeZone, days: days)!
        return ForecastViewModel(
            location: location,
            weather: StubWeatherRepository(result: .success(forecast)),
            state: .loaded(content, refresh: refresh)
        )
    }

    /// Starts in `state`. A `.loading` view model stays loading; otherwise retrying loads San Francisco's forecast.
    static func preview(location: Location, state: ForecastState) -> ForecastViewModel {
        ForecastViewModel(
            location: location,
            weather: StubWeatherRepository(result: state == .loading ? nil : .success(SampleData.sanFranciscoForecast)),
            state: state
        )
    }
}
