import Foundation

/// Finds places by name.
///
/// Implementations throw only `RepositoryError` or `CancellationError`.
nonisolated protocol GeocodingRepository: Sendable {
    func searchLocations(named query: String) async throws -> [Location]
}
