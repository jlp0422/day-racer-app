import Foundation

struct SwipePath: Codable, Sendable {
    let rawPoints: [CGPoint]
    let simplifiedPoints: [CGPoint]
    let smoothedPoints: [CGPoint]
    let didCrash: Bool
    let crashPoint: CGPoint?
    let crashSegmentIndex: Int?

    init(
        rawPoints: [CGPoint],
        simplifiedPoints: [CGPoint] = [],
        smoothedPoints: [CGPoint] = [],
        didCrash: Bool = false,
        crashPoint: CGPoint? = nil,
        crashSegmentIndex: Int? = nil
    ) {
        self.rawPoints = rawPoints
        self.simplifiedPoints = simplifiedPoints
        self.smoothedPoints = smoothedPoints
        self.didCrash = didCrash
        self.crashPoint = crashPoint
        self.crashSegmentIndex = crashSegmentIndex
    }
}
