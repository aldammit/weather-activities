import SwiftUI

struct ActivityRankingRow: View {
    let score: ActivityScore
    let isBest: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let headlineLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))

        VStack(alignment: .leading, spacing: 4) {
            headlineLayout {
                Label {
                    Text(score.activity.name)
                        .foregroundStyle(Color(.ink))
                } icon: {
                    Image(systemName: score.activity.symbolName)
                        .foregroundStyle(score.activity.tint)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 5) {
                    if isBest {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color(.bestHighlight))
                            .accessibilityHidden(true)
                    }
                    scoreText
                }
            }
            .font(.subheadline.weight(.semibold))

            Text(score.reason.explanation)
                .font(.subheadline)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
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
        .accessibilityElement(children: .combine)
    }

    private var scoreText: Text {
        if let value = score.score {
            Text(value, format: .score)
                .monospacedDigit()
                .foregroundStyle(isBest ? Color(.bestHighlight) : Color(.ink))
        } else {
            Text("No score")
                .foregroundStyle(Color(.ink))
        }
    }
}
