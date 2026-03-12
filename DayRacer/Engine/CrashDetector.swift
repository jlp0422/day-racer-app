import Foundation

struct CrashResult: Sendable {
    let crashPoint: CGPoint
    let boundarySide: BoundarySide
    let segmentIndex: Int
    let pathPointIndex: Int
}

enum CrashDetector {

    /// Checks a swipe path against track boundaries for intersection.
    /// Returns the first crash point found, or nil if no crash.
    static func detect(
        pathPoints: [CGPoint],
        innerBoundary: TrackBoundary,
        outerBoundary: TrackBoundary
    ) -> CrashResult? {
        guard pathPoints.count >= 2 else { return nil }

        let boundarySegments = innerBoundary.segments + outerBoundary.segments
        let innerCount = innerBoundary.segments.count

        for i in 0..<(pathPoints.count - 1) {
            let pathSeg = LineSegment(start: pathPoints[i], end: pathPoints[i + 1])
            let pathBB = pathSeg.boundingBox

            for (j, boundarySeg) in boundarySegments.enumerated() {
                // AABB broad-phase culling
                guard aabbOverlap(pathBB, boundarySeg.boundingBox) else { continue }

                if let intersection = lineIntersection(pathSeg, boundarySeg) {
                    let side: BoundarySide = j < innerCount ? .inner : .outer
                    let boundaryIndex = j < innerCount ? j : j - innerCount
                    return CrashResult(
                        crashPoint: intersection,
                        boundarySide: side,
                        segmentIndex: boundaryIndex,
                        pathPointIndex: i
                    )
                }
            }
        }
        return nil
    }

    /// Line-segment intersection using parametric form.
    /// Returns intersection point if segments cross, nil otherwise.
    static func lineIntersection(_ a: LineSegment, _ b: LineSegment) -> CGPoint? {
        let dx1 = a.end.x - a.start.x
        let dy1 = a.end.y - a.start.y
        let dx2 = b.end.x - b.start.x
        let dy2 = b.end.y - b.start.y

        let denom = dx1 * dy2 - dy1 * dx2
        guard abs(denom) > 1e-10 else { return nil } // Parallel or coincident

        let dx3 = b.start.x - a.start.x
        let dy3 = b.start.y - a.start.y

        let t = (dx3 * dy2 - dy3 * dx2) / denom
        let u = (dx3 * dy1 - dy3 * dx1) / denom

        guard t >= 0, t <= 1, u >= 0, u <= 1 else { return nil }

        return CGPoint(
            x: a.start.x + t * dx1,
            y: a.start.y + t * dy1
        )
    }

    /// AABB overlap check for broad-phase culling.
    static func aabbOverlap(_ a: CGRect, _ b: CGRect) -> Bool {
        a.minX <= b.maxX && a.maxX >= b.minX &&
        a.minY <= b.maxY && a.maxY >= b.minY
    }
}
