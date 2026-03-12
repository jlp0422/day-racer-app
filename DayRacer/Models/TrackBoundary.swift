import Foundation

struct TrackBoundary: Codable, Sendable {
    let points: [CGPoint]
    let side: BoundarySide
    let barrierStyle: BarrierStyle

    var segments: [LineSegment] {
        guard points.count >= 2 else { return [] }
        return zip(points, points.dropFirst()).map { LineSegment(start: $0, end: $1) }
    }
}
