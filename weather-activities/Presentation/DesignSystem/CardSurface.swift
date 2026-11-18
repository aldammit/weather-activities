import SwiftUI

extension View {
    /// Frosted rounded card used for content sections. Controls use Liquid Glass instead.
    func cardSurface() -> some View {
        background(.regularMaterial, in: .rect(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview {
    Text("Card content")
        .padding(24)
        .cardSurface()
        .padding()
        .background { SkyBackground() }
}
