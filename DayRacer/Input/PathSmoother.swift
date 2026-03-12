import Foundation

enum PathSmoother {

    /// Full smoothing pipeline: raw → Douglas-Peucker simplification → Catmull-Rom interpolation → smoothed
    /// - Parameters:
    ///   - rawPoints: Raw touch samples from gesture
    ///   - cornerType: Used to select appropriate Catmull-Rom alpha
    /// - Returns: (simplifiedPoints, smoothedPoints)
    static func smooth(
        rawPoints: [CGPoint],
        cornerType: CornerType
    ) -> (simplified: [CGPoint], smoothed: [CGPoint]) {
        guard rawPoints.count >= 2 else {
            return (rawPoints, rawPoints)
        }

        // Pass 1: Douglas-Peucker simplification
        let epsilon = GameConstants.Input.dpEpsilon
        let simplified = DouglasPeucker.simplify(rawPoints, epsilon: epsilon)

        // Pass 2: Catmull-Rom spline interpolation
        let alpha: CGFloat
        switch cornerType {
        case .hairpin:
            alpha = GameConstants.Input.crAlphaHairpin
        default:
            alpha = GameConstants.Input.crAlpha
        }

        let smoothed = CatmullRom.interpolate(
            simplified,
            alpha: alpha,
            samplesPerSegment: 12
        )

        return (simplified, smoothed)
    }
}
