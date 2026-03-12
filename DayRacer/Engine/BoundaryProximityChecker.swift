import Foundation

enum ProximityLevel: Sendable {
    case safe
    case warning
    case danger
}

enum BoundaryProximityChecker {

    /// Returns the minimum distance from a point to the nearest boundary segment.
    static func minimumDistance(
        from point: CGPoint,
        to boundary: TrackBoundary
    ) -> CGFloat {
        boundary.segments.reduce(CGFloat.infinity) { minDist, segment in
            min(minDist, distanceToSegment(point: point, segment: segment))
        }
    }

    /// Returns the minimum distance from a point to either boundary.
    static func minimumDistance(
        from point: CGPoint,
        innerBoundary: TrackBoundary,
        outerBoundary: TrackBoundary
    ) -> CGFloat {
        min(
            minimumDistance(from: point, to: innerBoundary),
            minimumDistance(from: point, to: outerBoundary)
        )
    }

    /// Returns the proximity level for a given distance.
    static func proximityLevel(distance: CGFloat) -> ProximityLevel {
        if distance < GameConstants.Rendering.proximityDanger {
            return .danger
        } else if distance < GameConstants.Rendering.proximityWarning {
            return .warning
        }
        return .safe
    }

    /// Returns proximity level for a point against both boundaries.
    static func check(
        point: CGPoint,
        innerBoundary: TrackBoundary,
        outerBoundary: TrackBoundary
    ) -> (distance: CGFloat, level: ProximityLevel) {
        let dist = minimumDistance(from: point, innerBoundary: innerBoundary, outerBoundary: outerBoundary)
        return (dist, proximityLevel(distance: dist))
    }

    /// Perpendicular distance from a point to a line segment.
    static func distanceToSegment(point: CGPoint, segment: LineSegment) -> CGFloat {
        let dx = segment.end.x - segment.start.x
        let dy = segment.end.y - segment.start.y
        let lengthSq = dx * dx + dy * dy

        guard lengthSq > 0 else {
            return hypot(point.x - segment.start.x, point.y - segment.start.y)
        }

        let t = max(0, min(1, ((point.x - segment.start.x) * dx + (point.y - segment.start.y) * dy) / lengthSq))
        let projX = segment.start.x + t * dx
        let projY = segment.start.y + t * dy

        return hypot(point.x - projX, point.y - projY)
    }
}
