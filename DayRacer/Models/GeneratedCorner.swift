import Foundation

struct GeneratedCorner: Sendable {
    let corner: Corner
    let centerline: [CGPoint]
    let innerBoundary: TrackBoundary
    let outerBoundary: TrackBoundary
    let idealLine: CornerPath
    let bezierSegments: [CubicBezier]
    let entryPoint: CGPoint
    let exitPoint: CGPoint
}
