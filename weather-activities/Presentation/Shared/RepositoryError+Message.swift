import Foundation

extension RepositoryError {
    var title: LocalizedStringResource {
        switch self {
        case .connectivity: "No Connection"
        case .httpStatus: "Service Unavailable"
        case .decoding, .malformedForecast: "Unexpected Data"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .connectivity:
            "Check your internet connection and try again."
        case .httpStatus(let statusCode):
            LocalizedStringResource(
                "The weather service returned error \(statusCode). Try again in a moment.",
                comment: "The variable is an HTTP status code, such as 503."
            )
        case .decoding:
            "The weather service sent a response this app couldn't read."
        case .malformedForecast:
            "The forecast for this place came back incomplete."
        }
    }

    var systemImage: String {
        switch self {
        case .connectivity: "wifi.exclamationmark"
        case .httpStatus: "exclamationmark.icloud"
        case .decoding, .malformedForecast: "exclamationmark.triangle"
        }
    }
}
