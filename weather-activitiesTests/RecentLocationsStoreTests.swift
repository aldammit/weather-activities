import Foundation
import Testing
@testable import weather_activities

struct RecentLocationsStoreTests {
    private let isolated = IsolatedDefaults()

    private var store: RecentLocationsStore {
        RecentLocationsStore(defaults: isolated.defaults)
    }

    @Test func startsEmpty() {
        #expect(store.load().isEmpty)
    }

    @Test func mostRecentComesFirst() {
        store.record(Fixtures.parisFrance)
        store.record(Fixtures.london)

        #expect(store.load() == [Fixtures.london, Fixtures.parisFrance])
    }

    @Test func recordingAgainMovesToTheFrontWithoutDuplicating() {
        store.record(Fixtures.parisFrance)
        store.record(Fixtures.london)
        store.record(Fixtures.parisFrance)

        #expect(store.load() == [Fixtures.parisFrance, Fixtures.london])
    }

    @Test func samePlaceNameWithDifferentIDsAreKeptApart() {
        store.record(Fixtures.parisFrance)
        store.record(Fixtures.parisTexas)

        #expect(store.load() == [Fixtures.parisTexas, Fixtures.parisFrance])
    }

    @Test func keepsAtMostFive() {
        for id in 1...7 {
            store.record(Fixtures.location(id: id))
        }

        #expect(store.load().map(\.id) == [7, 6, 5, 4, 3])
    }

    @Test func survivesANewStoreInstance() {
        store.record(Fixtures.parisTexas)

        #expect(RecentLocationsStore(defaults: isolated.defaults).load() == [Fixtures.parisTexas])
    }

    @Test func unreadableDataCountsAsEmpty() {
        isolated.defaults.set(Data("not json".utf8), forKey: "recentLocations")

        #expect(store.load().isEmpty)
        store.record(Fixtures.london)
        #expect(store.load() == [Fixtures.london])
    }
}
