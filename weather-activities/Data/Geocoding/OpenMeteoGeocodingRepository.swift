import Foundation

nonisolated struct OpenMeteoGeocodingRepository: GeocodingRepository {
    let client: OpenMeteoClient
    /// ISO 639-1 code for the language of the returned place names.
    var languageCode = Locale.current.language.languageCode?.identifier ?? "en"

    private static let endpoint = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

    func searchLocations(named query: String) async throws -> [Location] {
        let url = Self.endpoint.appending(queryItems: [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: languageCode),
            URLQueryItem(name: "format", value: "json"),
        ])
        let response: GeocodingResponseDTO = try await client.get(url)
        return (response.results ?? []).map { place in
            Location(
                id: place.id,
                name: place.name,
                region: place.admin1,
                country: place.country,
                latitude: place.latitude,
                longitude: place.longitude
            )
        }
    }
}
