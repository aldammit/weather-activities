import Foundation
import Observation

nonisolated enum ForecastState: Hashable, Sendable {
    /// First load: nothing to show yet.
    case loading
    /// Ranked days. The content stays on screen while a refresh runs and after one fails.
    case loaded(ForecastContent, refresh: RefreshStatus)
    /// The forecast had no usable days.
    case empty
    case failed(RepositoryError)

    /// The forecast on screen: the content in `.loaded`, otherwise `nil`.
    var content: ForecastContent? {
        guard case .loaded(let content, _) = self else { return nil }
        return content
    }
}

nonisolated enum RefreshStatus: Hashable, Sendable {
    case idle
    case refreshing
    case failed(RepositoryError)
}

/// What the loaded forecast screen shows.
nonisolated struct ForecastContent: Hashable, Sendable {
    /// The forecast location's time zone; day dates are midnights in it.
    let timeZone: TimeZone
    let days: [DayRecommendation]
    /// First through last day, for the "Nov 17 – 23" subtitle.
    let dateRange: Range<Date>

    /// Returns `nil` when there are no days to show.
    init?(timeZone: TimeZone, days: [DayRecommendation]) {
        guard let first = days.first, let last = days.last else { return nil }
        self.timeZone = timeZone
        self.days = days
        self.dateRange = first.weather.date..<last.weather.date
    }
}

@Observable
final class ForecastViewModel {
    let location: Location
    private(set) var state: ForecastState

    @ObservationIgnored private let weather: any WeatherRepository
    @ObservationIgnored private let recommender = ActivityRecommendationService()

    /// `state` sets a starting point for previews. `load()` only fetches from `.loading`.
    init(location: Location, weather: any WeatherRepository, state: ForecastState = .loading) {
        self.location = location
        self.weather = weather
        self.state = state
    }

    /// Initial load. Safe to call again: it does nothing once something is on screen.
    func load() async {
        guard state == .loading else { return }
        await fetch()
    }

    /// Fetches fresh data and keeps the current forecast visible until it arrives.
    /// Does nothing unless a forecast is loaded and no refresh is already running.
    func refresh() async {
        guard case .loaded(let content, let status) = state, status != .refreshing else { return }
        state = .loaded(content, refresh: .refreshing)
        await fetch()
    }

    /// Starts over from the loading state.
    func retry() async {
        state = .loading
        await fetch()
    }

    private func fetch() async {
        let shown = state.content  // kept on screen if this fetch fails or is cancelled
        do {
            let forecast = try await weather.forecast(for: location)
            let days = recommender.recommendations(for: forecast)
            if let content = ForecastContent(timeZone: forecast.timeZone, days: days) {
                state = .loaded(content, refresh: .idle)
            } else {
                state = .empty
            }
        } catch let error as RepositoryError {
            if let shown { state = .loaded(shown, refresh: .failed(error)) } else { state = .failed(error) }
        } catch {
            assert(error is CancellationError, "Repositories throw only RepositoryError or CancellationError")
            // Cancelled: put back what was shown, or stay in `.loading` so the next `load()` starts over.
            if let shown { state = .loaded(shown, refresh: .idle) }
        }
    }
}
