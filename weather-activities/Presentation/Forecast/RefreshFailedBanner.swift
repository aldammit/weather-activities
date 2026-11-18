import SwiftUI

/// Shown over a forecast that stayed on screen because refreshing it failed.
struct RefreshFailedBanner: View {
    let error: RepositoryError
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.systemImage)
                .font(.title3)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Couldn't refresh. Showing the earlier forecast.")
                .font(.subheadline)
                .foregroundStyle(Color(.ink))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Try Again", action: retry)
                .buttonStyle(.glass)
                .fixedSize()
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

#Preview {
    RefreshFailedBanner(error: .connectivity, retry: {})
        .padding()
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background { SkyBackground() }
}
