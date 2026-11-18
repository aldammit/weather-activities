import Foundation

/// A named place with coordinates, as found by geocoding.
nonisolated struct Location: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let name: String
    /// First-level administrative area, such as a state or region.
    let region: String?
    let country: String?
    let latitude: Double
    let longitude: Double
}
