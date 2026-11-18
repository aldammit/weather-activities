import Foundation
import Synchronization
@testable import weather_activities

/// Returns scripted results in order (the last one repeats) and records every query.
final class ScriptedGeocodingRepository: GeocodingRepository {
    private struct State {
        var results: [Result<[Location], RepositoryError>]
        var queries: [String] = []
    }

    private let state: Mutex<State>

    init(_ results: Result<[Location], RepositoryError>...) {
        state = Mutex(State(results: results))
    }

    var queries: [String] {
        state.withLock { $0.queries }
    }

    func searchLocations(named query: String) async throws -> [Location] {
        try state.withLock { state in
            state.queries.append(query)
            return state.results.count > 1 ? state.results.removeFirst() : state.results[0]
        }.get()
    }
}

/// Holds every search until the test responds, ignoring cancellation, so responses can arrive in any order.
actor ControlledGeocodingRepository: GeocodingRepository {
    /// Each query, as its search reaches the repository.
    nonisolated let requests: AsyncStream<String>
    private let requestsContinuation: AsyncStream<String>.Continuation
    private var pending: [String: CheckedContinuation<[Location], any Error>] = [:]

    init() {
        let (requests, continuation) = AsyncStream.makeStream(of: String.self)
        self.requests = requests
        self.requestsContinuation = continuation
    }

    func searchLocations(named query: String) async throws -> [Location] {
        try await withCheckedThrowingContinuation { continuation in
            pending[query] = continuation
            requestsContinuation.yield(query)
        }
    }

    func respond(to query: String, with locations: [Location]) {
        pending.removeValue(forKey: query)?.resume(returning: locations)
    }
}

/// Returns scripted results in order (the last one repeats) and counts the requests.
final class ScriptedWeatherRepository: WeatherRepository {
    private struct State {
        var results: [Result<Forecast, RepositoryError>]
        var requestCount = 0
    }

    private let state: Mutex<State>

    init(_ results: Result<Forecast, RepositoryError>...) {
        state = Mutex(State(results: results))
    }

    var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    func forecast(for location: Location) async throws -> Forecast {
        try state.withLock { state in
            state.requestCount += 1
            return state.results.count > 1 ? state.results.removeFirst() : state.results[0]
        }.get()
    }
}

/// A `UserDefaults` suite private to one test, deleted when released.
final class IsolatedDefaults {
    private let suiteName = "weather-activities-tests.\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
