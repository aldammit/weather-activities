import SwiftUI

extension Activity {
    var symbolName: String {
        switch self {
        case .surfing: "figure.surfing"
        case .outdoorSightseeing: "figure.hiking"
        case .indoorSightseeing: "building.classical.columns.fill"
        case .skiing: "figure.skiing.downhill"
        }
    }

    var tint: Color {
        switch self {
        case .surfing: .blue
        case .outdoorSightseeing: .green
        case .indoorSightseeing: .purple
        case .skiing: .cyan
        }
    }
}
