import SwiftUI

struct SearchHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find activities\nfor any city")
                .font(.largeTitle.bold())
                .foregroundStyle(Color(.ink))
                .accessibilityAddTraits(.isHeader)
            Text("Get a 7-day weather forecast and see which activities are best for the conditions.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SearchHeader()
        .padding()
        .background { SkyBackground() }
}
