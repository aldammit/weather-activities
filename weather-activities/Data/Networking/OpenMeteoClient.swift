import Foundation

/// Fetches and decodes Open-Meteo JSON off the main actor.
///
/// Throws only `RepositoryError` or `CancellationError`.
nonisolated struct OpenMeteoClient: Sendable {
    let transport: any HTTPTransport

    @concurrent
    func get<Response: Decodable & Sendable>(_ url: URL) async throws -> Response {
        let (data, response) = try await send(URLRequest(url: url))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.connectivity
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RepositoryError.httpStatus(httpResponse.statusCode)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw RepositoryError.decoding
        }
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await transport.send(request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as CancellationError {
            throw error
        } catch {
            throw RepositoryError.connectivity
        }
    }
}
