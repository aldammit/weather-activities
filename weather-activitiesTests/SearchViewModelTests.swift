import Foundation
import Testing
@testable import weather_activities

@MainActor
struct SearchViewModelTests {
    private let isolated = IsolatedDefaults()

    private func makeViewModel(
        _ geocoding: any GeocodingRepository,
        debounce: Duration = .zero
    ) -> SearchViewModel {
        SearchViewModel(geocoding: geocoding, recents: RecentLocationsStore(defaults: isolated.defaults), debounce: debounce)
    }

    @Test(arguments: ["", "P", " P  "])
    func queryShorterThanTwoCharactersStaysIdle(query: String) async {
        let geocoding = ScriptedGeocodingRepository(.success([Fixtures.parisFrance]))
        let viewModel = makeViewModel(geocoding)

        viewModel.query = query
        viewModel.submit()
        await viewModel.searchTask?.value

        #expect(viewModel.state == .idle)
        #expect(geocoding.queries.isEmpty)
    }

    @Test func showsResults() async {
        let geocoding = ScriptedGeocodingRepository(.success([Fixtures.parisFrance, Fixtures.parisTexas]))
        let viewModel = makeViewModel(geocoding)

        viewModel.query = "  Paris "
        #expect(viewModel.state == .searching)
        await viewModel.searchTask?.value

        #expect(viewModel.state == .results([Fixtures.parisFrance, Fixtures.parisTexas]))
        #expect(geocoding.queries == ["Paris"])
    }

    @Test func noMatchesIsEmpty() async {
        let viewModel = makeViewModel(ScriptedGeocodingRepository(.success([])))

        viewModel.query = "Xyzzy"
        await viewModel.searchTask?.value

        #expect(viewModel.state == .empty(query: "Xyzzy"))
    }

    @Test func failureIsShown() async {
        let viewModel = makeViewModel(ScriptedGeocodingRepository(.failure(.connectivity)))

        viewModel.query = "Paris"
        await viewModel.searchTask?.value

        #expect(viewModel.state == .failed(.connectivity))
    }

    @Test func retryAfterFailureShowsResults() async {
        let geocoding = ScriptedGeocodingRepository(.failure(.httpStatus(503)), .success([Fixtures.parisFrance]))
        let viewModel = makeViewModel(geocoding)
        viewModel.query = "Paris"
        await viewModel.searchTask?.value
        #expect(viewModel.state == .failed(.httpStatus(503)))

        viewModel.retry()
        await viewModel.searchTask?.value

        #expect(viewModel.state == .results([Fixtures.parisFrance]))
        #expect(geocoding.queries == ["Paris", "Paris"])
    }

    @Test func clearingTheQueryReturnsToIdle() async {
        let viewModel = makeViewModel(ScriptedGeocodingRepository(.success([Fixtures.parisFrance])))
        viewModel.query = "Paris"
        await viewModel.searchTask?.value

        viewModel.query = ""

        #expect(viewModel.state == .idle)
    }

    @Test func typingQuicklySearchesOnlyTheFinalQuery() async {
        let geocoding = ScriptedGeocodingRepository(.success([Fixtures.london]))
        let viewModel = makeViewModel(geocoding, debounce: .milliseconds(100))

        viewModel.query = "L"
        viewModel.query = "Lo"
        viewModel.query = "London"
        await viewModel.searchTask?.value

        #expect(geocoding.queries == ["London"])
        #expect(viewModel.state == .results([Fixtures.london]))
    }

    @Test func submitSkipsTheDebounce() async {
        let geocoding = ScriptedGeocodingRepository(.success([Fixtures.london]))
        let viewModel = makeViewModel(geocoding, debounce: .seconds(60))

        viewModel.query = "London"
        viewModel.submit()
        await viewModel.searchTask?.value

        #expect(geocoding.queries == ["London"])
        #expect(viewModel.state == .results([Fixtures.london]))
    }

    @Test func staleResponseIsIgnored() async {
        let geocoding = ControlledGeocodingRepository()
        var requests = geocoding.requests.makeAsyncIterator()
        let viewModel = makeViewModel(geocoding)

        viewModel.query = "London"
        #expect(await requests.next() == "London")
        let londonSearch = viewModel.searchTask

        viewModel.query = "Paris"
        #expect(await requests.next() == "Paris")

        await geocoding.respond(to: "Paris", with: [Fixtures.parisFrance])
        await viewModel.searchTask?.value
        #expect(viewModel.state == .results([Fixtures.parisFrance]))

        // London's search was cancelled, but the repository ignores cancellation and answers anyway.
        await geocoding.respond(to: "London", with: [Fixtures.london])
        await londonSearch?.value
        #expect(viewModel.state == .results([Fixtures.parisFrance]))
    }

    @Test func selectRecordsARecentSearch() {
        let viewModel = makeViewModel(ScriptedGeocodingRepository(.success([])))
        #expect(viewModel.recentLocations.isEmpty)

        viewModel.select(Fixtures.parisFrance)
        viewModel.select(Fixtures.parisTexas)

        #expect(viewModel.recentLocations == [Fixtures.parisTexas, Fixtures.parisFrance])
        #expect(RecentLocationsStore(defaults: isolated.defaults).load() == [Fixtures.parisTexas, Fixtures.parisFrance])
    }

    @Test func loadsRecentSearchesAtStart() {
        let store = RecentLocationsStore(defaults: isolated.defaults)
        store.record(Fixtures.london)

        let viewModel = makeViewModel(ScriptedGeocodingRepository(.success([])))

        #expect(viewModel.recentLocations == [Fixtures.london])
    }
}
