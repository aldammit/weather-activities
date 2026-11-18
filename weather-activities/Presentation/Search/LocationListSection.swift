import SwiftUI

/// A titled card of tappable locations, used for both recent searches and search results.
struct LocationListSection: View {
    let title: LocalizedStringKey
    let locations: [Location]
    let onSelect: (Location) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(locations) { location in
                    Button {
                        onSelect(location)
                    } label: {
                        LocationRow(location: location)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        if location.id != locations.last?.id {
                            Divider()
                                .padding(.leading, 58)
                        }
                    }
                }
            }
            .cardSurface()
        }
    }
}

#Preview {
    LocationListSection(title: "Recent searches", locations: SampleData.recentLocations, onSelect: { _ in })
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background { SkyBackground() }
}
