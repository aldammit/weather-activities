import Foundation

/// Something to do on a given day. Declaration order breaks ties between equal scores.
nonisolated enum Activity: CaseIterable, Hashable, Sendable {
    case surfing
    case outdoorSightseeing
    case indoorSightseeing
    case skiing

    var name: LocalizedStringResource {
        switch self {
        case .surfing: "Surfing"
        case .outdoorSightseeing: "Outdoor sightseeing"
        case .indoorSightseeing: "Indoor sightseeing"
        case .skiing: "Skiing"
        }
    }
}
