import SwiftUI

struct ActivityTile: View {
    let activity: Activity
    /// `nil` when the forecast lacks the data to score this activity.
    let score: Double?
    let isBest: Bool

    /// Lifts the crown so it straddles the tile's top edge.
    @ScaledMetric(relativeTo: .caption) private var crownLift = 9.0

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: activity.symbolName)
                .font(.title3)
                .foregroundStyle(activity.tint)
                .opacity(score == nil ? 0.4 : 1)
            scoreText
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isBest ? Color(.bestHighlight) : score == nil ? Color.secondary : Color(.ink))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            if isBest {
                shape
                    .fill(Color(.bestHighlight).opacity(0.16))
                    .overlay {
                        shape.strokeBorder(Color(.bestHighlight).opacity(0.45), lineWidth: 1.5)
                    }
            } else {
                shape.fill(.fill.quaternary)
            }
        }
        .overlay(alignment: .top) {
            if isBest {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .offset(y: -crownLift)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(activity.name))
        .accessibilityValue(accessibilityValue)
    }

    private var scoreText: Text {
        if let score {
            Text(score, format: .score)
        } else {
            Text(verbatim: "–")
        }
    }

    private var accessibilityValue: Text {
        if let score {
            Text(score, format: .score)
        } else {
            Text("No data")
        }
    }
}

#Preview("Best") {
    ActivityTile(activity: .surfing, score: 0.92, isBest: true)
        .frame(width: 80)
        .padding()
}

#Preview("Normal") {
    ActivityTile(activity: .indoorSightseeing, score: 0.56, isBest: false)
        .frame(width: 80)
        .padding()
}

#Preview("No data") {
    ActivityTile(activity: .surfing, score: nil, isBest: false)
        .frame(width: 80)
        .padding()
}
