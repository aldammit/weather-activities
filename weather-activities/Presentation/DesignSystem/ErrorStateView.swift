import SwiftUI

/// Full-screen "nothing to show" message, for failures and empty results, with a "Try Again" button.
struct ErrorStateView: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let systemImage: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.glassProminent)
        }
    }
}

extension ErrorStateView {
    init(error: RepositoryError, retry: @escaping () -> Void) {
        self.init(title: error.title, message: error.message, systemImage: error.systemImage, retry: retry)
    }
}

#Preview {
    ErrorStateView(
        title: "No Connection",
        message: "Check your internet connection and try again.",
        systemImage: "wifi.exclamationmark",
        retry: {}
    )
    .background { SkyBackground() }
}
