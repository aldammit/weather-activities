import SwiftUI

struct SearchScreen: View {
    @Bindable var viewModel: SearchViewModel
    let onSelect: (Location) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                SearchHeader()
                SearchField(query: $viewModel.query, onSubmit: { viewModel.submit() })
                SearchStateContent(
                    state: viewModel.state,
                    recentLocations: viewModel.recentLocations,
                    onSelect: onSelect,
                    onRetry: { viewModel.retry() }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 32)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background { SkyBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

/// Everything below the search field.
private struct SearchStateContent: View {
    let state: SearchState
    let recentLocations: [Location]
    let onSelect: (Location) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            if !recentLocations.isEmpty {
                LocationListSection(title: "Recent searches", locations: recentLocations, onSelect: onSelect)
            }
        case .searching:
            ProgressView("Searching…")
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        case .results(let locations):
            LocationListSection(title: "Choose a place", locations: locations, onSelect: onSelect)
        case .empty(let query):
            ContentUnavailableView.search(text: query)
        case .failed(let error):
            ErrorStateView(error: error, retry: onRetry)
        }
    }
}

#Preview("Idle") {
    NavigationStack {
        SearchScreen(viewModel: .preview(), onSelect: { _ in })
    }
}

#Preview("Searching") {
    NavigationStack {
        SearchScreen(viewModel: .preview(query: "Pari", state: .searching), onSelect: { _ in })
    }
}

#Preview("Results") {
    NavigationStack {
        SearchScreen(viewModel: .preview(query: "Paris", state: .results(SampleData.parisResults)), onSelect: { _ in })
    }
}

#Preview("Empty") {
    NavigationStack {
        SearchScreen(viewModel: .preview(query: "Xyzzy", state: .empty(query: "Xyzzy")), onSelect: { _ in })
    }
}

#Preview("Failed") {
    NavigationStack {
        SearchScreen(viewModel: .preview(query: "Paris", state: .failed(.connectivity)), onSelect: { _ in })
    }
}

#Preview("Dark") {
    NavigationStack {
        SearchScreen(viewModel: .preview(query: "Paris", state: .results(SampleData.parisResults)), onSelect: { _ in })
    }
    .preferredColorScheme(.dark)
}
