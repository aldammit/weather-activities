import SwiftUI

struct ForecastScreen: View {
    @State private var viewModel: ForecastViewModel

    init(viewModel: ForecastViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ForecastStateContent(
            state: viewModel.state,
            onRefresh: { await viewModel.refresh() },
            onRetry: { Task { await viewModel.retry() } }
        )
        .background { SkyBackground(fadeEnd: UnitPoint(x: 0.5, y: 0.4)) }
        .navigationTitle(viewModel.location.name)
        .navigationSubtitle(subtitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if case .loaded(_, let refresh) = viewModel.state {
                ToolbarItem(placement: .primaryAction) {
                    if refresh == .refreshing {
                        ProgressView()
                    } else {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await viewModel.refresh() }
                        }
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }

    /// "Texas, United States · Nov 17 – 23", with dates in the forecast location's time zone.
    private var subtitle: Text {
        let place = Text(viewModel.location.detail ?? "")
        guard let content = viewModel.state.content else { return place }
        let dates = Text(
            content.dateRange,
            format: Date.IntervalFormatStyle(timeZone: content.timeZone).day().month(.abbreviated)
        )
        return viewModel.location.detail == nil ? dates : Text("\(place) · \(dates)")
    }
}

private struct ForecastStateContent: View {
    let state: ForecastState
    let onRefresh: () async -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let content, let refresh):
            ForecastDaysList(content: content)
                .refreshable { await onRefresh() }
                .safeAreaInset(edge: .bottom) {
                    if case .failed(let error) = refresh {
                        RefreshFailedBanner(error: error, retry: { Task { await onRefresh() } })
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .frame(maxWidth: 680)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.default, value: refresh)
                .environment(\.timeZone, content.timeZone)
        case .empty:
            ErrorStateView(
                title: "No Forecast",
                message: "There's no usable forecast for this place right now.",
                systemImage: "cloud.sun",
                retry: onRetry
            )
        case .failed(let error):
            ErrorStateView(error: error, retry: onRetry)
        }
    }
}

private struct ForecastDaysList: View {
    let content: ForecastContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Day by day")
                    .font(.title3.bold())
                    .foregroundStyle(Color(.ink))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 10)
                    .padding(.horizontal, 4)
                ForEach(content.days) { day in
                    DayForecastRow(day: day)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Loaded, coastal") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.sanFrancisco, forecast: SampleData.sanFranciscoForecast))
    }
}

#Preview("Loaded, inland") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.chamonix, forecast: SampleData.chamonixForecast))
    }
}

#Preview("Loading") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.sanFrancisco, state: .loading))
    }
}

#Preview("Failed") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.sanFrancisco, state: .failed(.connectivity)))
    }
}

#Preview("Refresh failed") {
    NavigationStack {
        ForecastScreen(
            viewModel: .preview(
                location: SampleData.sanFrancisco,
                forecast: SampleData.sanFranciscoForecast,
                refresh: .failed(.connectivity)
            )
        )
    }
}

#Preview("Accessibility XXXL") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.sanFrancisco, forecast: SampleData.sanFranciscoForecast))
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    NavigationStack {
        ForecastScreen(viewModel: .preview(location: SampleData.chamonix, forecast: SampleData.chamonixForecast))
    }
    .preferredColorScheme(.dark)
}
