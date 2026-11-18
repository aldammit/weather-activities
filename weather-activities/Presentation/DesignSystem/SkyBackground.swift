import SwiftUI

/// Full-bleed sky gradient that fades into the surface colour at `fadeEnd`.
struct SkyBackground: View {
    var fadeEnd: UnitPoint = UnitPoint(x: 0.5, y: 0.6)

    var body: some View {
        LinearGradient(
            colors: [Color(.skyTop), Color(.skySurface)],
            startPoint: .top,
            endPoint: fadeEnd
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SkyBackground()
}
