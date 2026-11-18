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

    private func makeViewModel(
        _ weather: any WeatherRepository,
        state: ForecastState = .loading
    ) -> ForecastViewModel {
        ForecastViewModel(location: Fixtures.parisTexas, weather: weather, state: state)
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

    @Test func overlappingLoadAndRetryAreIgnored() async throws {
        let expected = try content(for: sunnyThenRainy)
        let weather = ControlledWeatherRepository(subsequentForecast: snowy)
        let viewModel = makeViewModel(weather)
        let firstLoad = Task { await viewModel.load() }
        await weather.waitForFirstRequest()

        await viewModel.load()
        await viewModel.retry()

        #expect(await weather.requestCount == 1)
        #expect(viewModel.state == .loading)
        await weather.finishFirstRequest(with: .success(sunnyThenRainy))
        await firstLoad.value
        #expect(viewModel.state == .loaded(expected, refresh: .idle))
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

    @Test(arguments: [ForecastState.failed(.connectivity), .empty])
    func retryStartsOnlyOneRequest(previousState: ForecastState) async throws {
        let expected = try content(for: sunnyThenRainy)
        let weather = ControlledWeatherRepository(subsequentForecast: snowy)
        let viewModel = makeViewModel(weather, state: previousState)
        let firstRetry = Task { await viewModel.retry() }
        await weather.waitForFirstRequest()

        #expect(viewModel.state == .loading)
        await viewModel.retry()
        await viewModel.load()

        #expect(await weather.requestCount == 1)
        await weather.finishFirstRequest(with: .success(sunnyThenRainy))
        await firstRetry.value
        #expect(viewModel.state == .loaded(expected, refresh: .idle))
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
        let shown = try content(for: sunnyThenRainy)
        let expected = try content(for: snowy)
        let weather = ControlledWeatherRepository(subsequentForecast: sunnyThenRainy)
        let viewModel = makeViewModel(weather, state: .loaded(shown, refresh: .idle))
        let firstRefresh = Task { await viewModel.refresh() }
        await weather.waitForFirstRequest()

        #expect(viewModel.state == .loaded(shown, refresh: .refreshing))
        await viewModel.refresh()
        await viewModel.retry()
        await viewModel.load()

        #expect(await weather.requestCount == 1)
        #expect(viewModel.state == .loaded(shown, refresh: .refreshing))
        await weather.finishFirstRequest(with: .success(snowy))
        await firstRefresh.value
        #expect(viewModel.state == .loaded(expected, refresh: .idle))
    }

    @Test(arguments: [nil, .httpStatus(503)] as [RepositoryError?])
    func cancelledRefreshRestoresPreviousState(lateError: RepositoryError?) async throws {
        let shown = try content(for: sunnyThenRainy)
        let expected = try content(for: snowy)
        let previousState = ForecastState.loaded(shown, refresh: .failed(.connectivity))
        let weather = ControlledWeatherRepository(subsequentForecast: snowy)
        let viewModel = makeViewModel(weather, state: previousState)
        let firstRefresh = Task { await viewModel.refresh() }
        await weather.waitForFirstRequest()

        firstRefresh.cancel()
        await viewModel.refresh()
        #expect(await weather.requestCount == 1)

        let lateResult: Result<Forecast, any Error> = if let lateError {
            .failure(lateError)
        } else {
            .success(snowy)
        }
        await weather.finishFirstRequest(with: lateResult)
        await firstRefresh.value
        #expect(viewModel.state == previousState)

        await viewModel.refresh()
        #expect(await weather.requestCount == 2)
        #expect(viewModel.state == .loaded(expected, refresh: .idle))
    }

    @Test func repositoryCancellationRestoresRetryState() async {
        let previousState = ForecastState.failed(.connectivity)
        let weather = ControlledWeatherRepository(subsequentForecast: snowy)
        let viewModel = makeViewModel(weather, state: previousState)
        let retry = Task { await viewModel.retry() }
        await weather.waitForFirstRequest()

        await weather.finishFirstRequest(with: .failure(CancellationError()))
        await retry.value

        #expect(viewModel.state == previousState)
    }

    @Test func taskCancelledBeforeFetchLeavesStateIntact() async throws {
        let previousState = ForecastState.loaded(try content(for: sunnyThenRainy), refresh: .idle)
        let weather = ScriptedWeatherRepository(.success(snowy))
        let viewModel = makeViewModel(weather, state: previousState)
        let refresh = Task { await viewModel.refresh() }
        refresh.cancel()
        await refresh.value

        #expect(weather.requestCount == 0)
        #expect(viewModel.state == previousState)
    }

    @Test func noUsableDaysIsEmpty() async {
        let empty = Fixtures.forecast([])
        let viewModel = makeViewModel(ScriptedWeatherRepository(.success(empty)))

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }
}

/// Suspends the first request until the test responds, even if its task is cancelled.
/// Extra requests return immediately so an overlap fails the test on the request count.
private actor ControlledWeatherRepository: WeatherRepository {
    private let firstRequestStarted: AsyncStream<Void>
    private let startSignal: AsyncStream<Void>.Continuation
    private let subsequentForecast: Forecast
    private var firstResponse: CheckedContinuation<Forecast, any Error>?
    private(set) var requestCount = 0

    init(subsequentForecast: Forecast) {
        self.subsequentForecast = subsequentForecast
        (firstRequestStarted, startSignal) = AsyncStream.makeStream(of: Void.self)
    }

    func waitForFirstRequest() async {
        var starts = firstRequestStarted.makeAsyncIterator()
        _ = await starts.next()
    }

    func forecast(for location: Location) async throws -> Forecast {
        requestCount += 1
        guard requestCount == 1 else { return subsequentForecast }
        return try await withCheckedThrowingContinuation { continuation in
            firstResponse = continuation
            startSignal.yield(())
            startSignal.finish()
        }
    }

    func finishFirstRequest(with result: Result<Forecast, any Error>) {
        let response = firstResponse
        firstResponse = nil
        response?.resume(with: result)
    }
}
