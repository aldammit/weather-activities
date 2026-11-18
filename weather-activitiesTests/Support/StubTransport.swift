import Foundation
import Synchronization
import Testing
@testable import weather_activities

/// Answers requests with canned responses chosen by host and path, and records every request.
final class StubTransport: HTTPTransport {
    enum Response: Sendable {
        case json(String, status: Int = 200)
        case failure(URLError)
    }

    enum Endpoint: String, Sendable {
        case geocoding = "geocoding-api.open-meteo.com/v1/search"
        case forecast = "api.open-meteo.com/v1/forecast"
        case marine = "marine-api.open-meteo.com/v1/marine"
    }

    private let responses: [Endpoint: Response]
    private let recordedRequests = Mutex<[URLRequest]>([])

    init(_ responses: [Endpoint: Response]) {
        self.responses = responses
    }

    var requests: [URLRequest] {
        recordedRequests.withLock { $0 }
    }

    func requests(to endpoint: Endpoint) -> [URLRequest] {
        requests.filter { Self.endpoint(of: $0) == endpoint }
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        recordedRequests.withLock { $0.append(request) }
        let url = try #require(request.url)
        let endpoint = try #require(Self.endpoint(of: request), "Unexpected request to \(url)")
        switch try #require(responses[endpoint], "No stubbed response for \(endpoint)") {
        case .json(let body, let status):
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        case .failure(let error):
            throw error
        }
    }

    private static func endpoint(of request: URLRequest) -> Endpoint? {
        guard let url = request.url, let host = url.host() else { return nil }
        return Endpoint(rawValue: host + url.path())
    }
}
