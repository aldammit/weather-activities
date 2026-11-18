import Foundation
import Observation

nonisolated enum SearchState: Hashable, Sendable {
    /// Query shorter than `SearchViewModel.minimumQueryLength`: show recent searches.
    case idle
    case searching
    /// The user picks the exact place, such as Paris, France vs. Paris, Texas.
    case results([Location])
    case empty(query: String)
    case failed(RepositoryError)
}

@Observable
final class SearchViewModel {
    /// Open-Meteo returns nothing for a single character.
    static let minimumQueryLength = 2

    var query: String {
        didSet { search(debounced: true) }
    }

    private(set) var state: SearchState
    private(set) var recentLocations: [Location]

    /// The latest lookup. Exposed so tests can await it.
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?

    @ObservationIgnored private let geocoding: any GeocodingRepository
    @ObservationIgnored private let recents: RecentLocationsStore
    @ObservationIgnored private let debounce: Duration

    /// `query` and `state` set a starting point for previews; they don't trigger a search.
    init(
        geocoding: any GeocodingRepository,
        recents: RecentLocationsStore,
        debounce: Duration = .milliseconds(300),
        query: String = "",
        state: SearchState = .idle
    ) {
        self.geocoding = geocoding
        self.recents = recents
        self.debounce = debounce
        self.query = query
        self.state = state
        self.recentLocations = recents.load()
    }

    func submit() {
        search(debounced: false)
    }

    func retry() {
        search(debounced: false)
    }

    func select(_ location: Location) {
        recents.record(location)
        recentLocations = recents.load()
    }

    private func search(debounced: Bool) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= Self.minimumQueryLength else {
            state = .idle
            searchTask = nil
            return
        }

        state = .searching
        searchTask = Task { [geocoding, debounce] in
            do {
                if debounced {
                    try await Task.sleep(for: debounce)
                }
                let locations = try await geocoding.searchLocations(named: trimmedQuery)
                // A newer search replaced this one while it was in flight.
                guard !Task.isCancelled else { return }
                state = locations.isEmpty ? .empty(query: trimmedQuery) : .results(locations)
            } catch let error as RepositoryError {
                // A newer search replaced this one while it was in flight.
                guard !Task.isCancelled else { return }
                state = .failed(error)
            } catch {
                assert(error is CancellationError, "Repositories throw only RepositoryError or CancellationError")
            }
        }
    }
}
