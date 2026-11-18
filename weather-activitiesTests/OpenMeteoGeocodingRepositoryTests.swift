import Foundation
import Testing
@testable import weather_activities

struct OpenMeteoGeocodingRepositoryTests {
    private func makeRepository(_ response: StubTransport.Response) -> (OpenMeteoGeocodingRepository, StubTransport) {
        let transport = StubTransport([.geocoding: response])
        let repository = OpenMeteoGeocodingRepository(client: OpenMeteoClient(transport: transport), languageCode: "en")
        return (repository, transport)
    }

    @Test func mapsResultsToLocations() async throws {
        let (repository, _) = makeRepository(.json(Fixtures.parisSearchJSON))

        let locations = try await repository.searchLocations(named: "Paris")

        #expect(locations == [Fixtures.parisFrance, Fixtures.parisTexas, Fixtures.parisTennessee])
    }

    @Test func missingAdmin1MapsToNoRegion() async throws {
        let (repository, _) = makeRepository(.json(Fixtures.singaporeSearchJSON))

        let locations = try await repository.searchLocations(named: "Singapore")

        #expect(locations == [
            Location(
                id: 1880252, name: "Singapore", region: nil, country: "Singapore",
                latitude: 1.28967, longitude: 103.85007
            ),
        ])
    }

    @Test func missingResultsKeyMeansNoMatches() async throws {
        let (repository, _) = makeRepository(.json(Fixtures.noMatchesSearchJSON))

        let locations = try await repository.searchLocations(named: "Xyzzyqq")

        #expect(locations.isEmpty)
    }

    @Test func percentEncodesTheQuery() async throws {
        let (repository, transport) = makeRepository(.json(Fixtures.noMatchesSearchJSON))

        _ = try await repository.searchLocations(named: "São Paulo")

        let url = try #require(transport.requests.first?.url)
        #expect(url.absoluteString.contains("name=S%C3%A3o%20Paulo"))
        let queryItems = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(queryItems == [
            URLQueryItem(name: "name", value: "São Paulo"),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ])
    }

    @Test(arguments: [
        (StubTransport.Response.json("{}", status: 500), RepositoryError.httpStatus(500)),
        (.failure(URLError(.notConnectedToInternet)), .connectivity),
        (.json("<html>Bad gateway</html>"), .decoding),
    ])
    func translatesFailures(response: StubTransport.Response, expected: RepositoryError) async {
        let (repository, _) = makeRepository(response)

        await #expect(throws: expected) {
            try await repository.searchLocations(named: "Paris")
        }
    }

    @Test func cancelledRequestThrowsCancellationError() async {
        let (repository, _) = makeRepository(.failure(URLError(.cancelled)))

        await #expect(throws: CancellationError.self) {
            try await repository.searchLocations(named: "Paris")
        }
    }
}
