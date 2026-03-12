import Foundation

enum CatmullRom {

    /// Generates a smooth curve through control points using centripetal Catmull-Rom interpolation.
    /// - Parameters:
    ///   - points: Control points (minimum 2)
    ///   - alpha: Parameterization: 0.0 = uniform, 0.5 = centripetal, 1.0 = chordal
    ///   - samplesPerSegment: Number of output points per segment between control points
    /// - Returns: Densely sampled smooth curve points
    static func interpolate(
        _ points: [CGPoint],
        alpha: CGFloat = 0.5,
        samplesPerSegment: Int = 10
    ) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        guard points.count >= 3 else {
            // With only 2 points, linearly interpolate
            return linearInterpolate(points[0], points[1], samples: samplesPerSegment)
        }

        var result: [CGPoint] = []

        // For each segment between points[i] and points[i+1], we need
        // P0 = points[i-1], P1 = points[i], P2 = points[i+1], P3 = points[i+2]
        // Mirror endpoints for first/last segments
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : mirror(points[1], over: points[0])
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : mirror(points[points.count - 2], over: points[points.count - 1])

            let segment = interpolateSegment(p0: p0, p1: p1, p2: p2, p3: p3, alpha: alpha, samples: samplesPerSegment)

            if i == 0 {
                result.append(contentsOf: segment)
            } else {
                // Skip first point to avoid duplicates at segment joins
                result.append(contentsOf: segment.dropFirst())
            }
        }

        return result
    }

    /// Interpolate a single Catmull-Rom segment between p1 and p2.
    private static func interpolateSegment(
        p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint,
        alpha: CGFloat,
        samples: Int
    ) -> [CGPoint] {
        let t0: CGFloat = 0
        let t1 = knotValue(t: t0, p0: p0, p1: p1, alpha: alpha)
        let t2 = knotValue(t: t1, p0: p1, p1: p2, alpha: alpha)
        let t3 = knotValue(t: t2, p0: p2, p1: p3, alpha: alpha)

        var points: [CGPoint] = []
        for i in 0..<samples {
            let t = t1 + (t2 - t1) * CGFloat(i) / CGFloat(samples - 1)

            let a1 = timeLerp(p0, p1, t0: t0, t1: t1, t: t)
            let a2 = timeLerp(p1, p2, t0: t1, t1: t2, t: t)
            let a3 = timeLerp(p2, p3, t0: t2, t1: t3, t: t)

            let b1 = timeLerp(a1, a2, t0: t0, t1: t2, t: t)
            let b2 = timeLerp(a2, a3, t0: t1, t1: t3, t: t)

            let c = timeLerp(b1, b2, t0: t1, t1: t2, t: t)
            points.append(c)
        }
        return points
    }

    /// Compute knot value using centripetal parameterization
    private static func knotValue(t: CGFloat, p0: CGPoint, p1: CGPoint, alpha: CGFloat) -> CGFloat {
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        let distSq = dx * dx + dy * dy
        return t + pow(distSq, alpha / 2)
    }

    /// Time-parameterized lerp between two points
    private static func timeLerp(_ a: CGPoint, _ b: CGPoint, t0: CGFloat, t1: CGFloat, t: CGFloat) -> CGPoint {
        guard t1 != t0 else { return a }
        let f = (t - t0) / (t1 - t0)
        return CGPoint(
            x: a.x + f * (b.x - a.x),
            y: a.y + f * (b.y - a.y)
        )
    }

    /// Mirror point `a` over point `center`
    private static func mirror(_ a: CGPoint, over center: CGPoint) -> CGPoint {
        CGPoint(x: 2 * center.x - a.x, y: 2 * center.y - a.y)
    }

    /// Simple linear interpolation between two points
    private static func linearInterpolate(_ a: CGPoint, _ b: CGPoint, samples: Int) -> [CGPoint] {
        (0..<samples).map { i in
            let t = CGFloat(i) / CGFloat(samples - 1)
            return CGPoint(x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y))
        }
    }
}
