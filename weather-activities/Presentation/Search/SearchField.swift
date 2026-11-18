import SwiftUI

struct SearchField: View {
    @Binding var query: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search for a city", text: $query)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)
            if !query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    query = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(.rect(cornerRadius: 20))
        .onTapGesture { isFocused = true }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    @Previewable @State var query = "Paris"
    SearchField(query: $query, onSubmit: {})
        .padding()
        .background { SkyBackground() }
}
