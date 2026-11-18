import Foundation

/// Provides daily forecasts for a location.
///
/// Implementations throw only `RepositoryError` or `CancellationError`.
nonisolated protocol WeatherRepository: Sendable {
    func forecast(for location: Location) async throws -> Forecast
}
