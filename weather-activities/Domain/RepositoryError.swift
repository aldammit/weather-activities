import Foundation

/// Every way a repository can fail, other than cancellation.
nonisolated enum RepositoryError: Error, Hashable {
    /// The request never got a response: offline, timed out, DNS failure and so on.
    case connectivity
    /// The server answered with a non-2xx status code.
    case httpStatus(Int)
    /// The response body didn't match the expected format.
    case decoding
    /// The forecast decoded but is inconsistent: unknown time zone, unparseable dates or uneven arrays.
    case malformedForecast
}
