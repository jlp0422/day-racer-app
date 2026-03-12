import Foundation

enum DouglasPeucker {

    /// Simplifies a polyline by removing points within `epsilon` perpendicular distance.
    /// Preserves start and end points. Returns simplified point array.
    static func simplify(_ points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var maxDist: CGFloat = 0
        var maxIndex = 0

        let start = points.first!
        let end = points.last!

        for i in 1..<(points.count - 1) {
            let dist = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if dist > maxDist {
                maxDist = dist
                maxIndex = i
            }
        }

        if maxDist > epsilon {
            let left = simplify(Array(points[...maxIndex]), epsilon: epsilon)
            let right = simplify(Array(points[maxIndex...]), epsilon: epsilon)
            // Join, avoiding duplicate at maxIndex
            return Array(left.dropLast()) + right
        } else {
            return [start, end]
        }
    }

    /// Perpendicular distance from a point to a line segment.
    static func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lengthSq = dx * dx + dy * dy

        guard lengthSq > 0 else {
            return hypot(point.x - lineStart.x, point.y - lineStart.y)
        }

        // Project point onto line, clamped to segment
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lengthSq))
        let projX = lineStart.x + t * dx
        let projY = lineStart.y + t * dy

        return hypot(point.x - projX, point.y - projY)
    }
}
