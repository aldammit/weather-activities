import Foundation
import Testing
@testable import weather_activities

@MainActor
struct ForecastViewModelTests {
    private let sunnyThenRainy = Fixtures.forecast([
        Fixtures.day(.clear, high: 22, precipitation: 0, wind: 10),
        Fixtures.day(.rain, high: 14, precipitation: 12, wind: 25),
    ])
    private let snowy = Fixtures.forecast([
        Fixtures.day(.snow, high: -5, precipitation: 12, snowfall: 15, wind: 15),
    ])

    private func makeViewModel(_ weather: ScriptedWeatherRepository) -> ForecastViewModel {
        ForecastViewModel(location: Fixtures.parisTexas, weather: weather)
    }

    private func content(for forecast: Forecast) throws -> ForecastContent {
        let days = ActivityRecommendationService().recommendations(for: forecast)
        return try #require(ForecastContent(timeZone: forecast.timeZone, days: days))
    }

    @Test func loadShowsRankedDays() async throws {
        let weather = ScriptedWeatherRepository(.success(sunnyThenRainy))
        let viewModel = makeViewModel(weather)
        #expect(viewModel.state == .loading)

        await viewModel.load()

        #expect(viewModel.state == .loaded(try content(for: sunnyThenRainy), refresh: .idle))
        guard case .loaded(let loaded, _) = viewModel.state else { return }
        #expect(loaded.days.map { $0.best?.activity } == [.outdoorSightseeing, .indoorSightseeing])
        #expect(loaded.timeZone == sunnyThenRainy.timeZone)
        #expect(weather.requestCount == 1)
    }

    @Test func loadDoesNothingOnceLoaded() async {
        let weather = ScriptedWeatherRepository(.success(sunnyThenRainy))
        let viewModel = makeViewModel(weather)

        await viewModel.load()
        await viewModel.load()

        #expect(weather.requestCount == 1)
    }

    @Test func failureThenRetry() async throws {
        let weather = ScriptedWeatherRepository(.failure(.connectivity), .success(sunnyThenRainy))
        let viewModel = makeViewModel(weather)

        await viewModel.load()
        #expect(viewModel.state == .failed(.connectivity))

        await viewModel.retry()
        #expect(viewModel.state == .loaded(try content(for: sunnyThenRainy), refresh: .idle))
        #expect(weather.requestCount == 2)
    }

    @Test func refreshFailureKeepsTheContent() async throws {
        let weather = ScriptedWeatherRepository(.success(sunnyThenRainy), .failure(.httpStatus(503)))
        let viewModel = makeViewModel(weather)
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.state == .loaded(try content(for: sunnyThenRainy), refresh: .failed(.httpStatus(503))))
    }

    @Test func refreshSuccessReplacesTheContentAndReloads() async throws {
        let weather = ScriptedWeatherRepository(.success(sunnyThenRainy), .success(snowy))
        let viewModel = makeViewModel(weather)
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.state == .loaded(try content(for: snowy), refresh: .idle))
        #expect(weather.requestCount == 2)
    }

    @Test func refreshDoesNothingUnlessLoaded() async {
        let weather = ScriptedWeatherRepository(.failure(.connectivity), .success(snowy))
        let viewModel = makeViewModel(weather)
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.state == .failed(.connectivity))
        #expect(weather.requestCount == 1)
    }

    @Test func refreshWhileRefreshingIsIgnored() async throws {
        let weather = ScriptedWeatherRepository(.success(snowy))
        let refreshing = ForecastState.loaded(try content(for: sunnyThenRainy), refresh: .refreshing)
        let viewModel = ForecastViewModel(location: Fixtures.parisTexas, weather: weather, state: refreshing)

        await viewModel.refresh()

        #expect(viewModel.state == refreshing)
        #expect(weather.requestCount == 0)
    }

    @Test func noUsableDaysIsEmpty() async {
        let empty = Fixtures.forecast([])
        let viewModel = makeViewModel(ScriptedWeatherRepository(.success(empty)))

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }
}
