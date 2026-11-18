import Foundation

/// Response of Open-Meteo's `/v1/search` endpoint.
nonisolated struct GeocodingResponseDTO: Decodable, Sendable {
    /// Open-Meteo omits this key entirely when nothing matches.
    let results: [Place]?

    nonisolated struct Place: Decodable, Sendable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let admin1: String?
        let country: String?
    }
}
