import SwiftUI

/// Displays a single corner rendered on a Canvas.
/// Used for track preview and will be the base for the race screen.
struct TrackCanvasView: View {
    let generatedCorner: GeneratedCorner

    var body: some View {
        Canvas { context, size in
            TrackRenderer.render(corner: generatedCorner, in: &context, size: size)
            TrackRenderer.drawStartZone(at: generatedCorner.entryPoint, in: &context)
            TrackRenderer.drawFinishZone(at: generatedCorner.exitPoint, in: &context)
        }
        .ignoresSafeArea()
    }
}
