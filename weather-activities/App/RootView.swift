import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @State private var searchViewModel: SearchViewModel
    @State private var path: [Location] = []

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.searchViewModel = SearchViewModel(geocoding: dependencies.geocoding, recents: dependencies.recents)
    }

    var body: some View {
        NavigationStack(path: $path) {
            SearchScreen(viewModel: searchViewModel) { location in
                searchViewModel.select(location)
                path.append(location)
            }
            .navigationDestination(for: Location.self) { location in
                ForecastScreen(viewModel: ForecastViewModel(location: location, weather: dependencies.weather))
            }
        }
    }
}

#Preview {
    RootView(dependencies: .preview())
}
