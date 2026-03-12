import Foundation

struct CornerPath: Codable, Sendable {
    let points: [CGPoint]
    let entryPoint: CGPoint
    let apexPoints: [CGPoint]
    let exitPoint: CGPoint
    let bezierSegments: [CubicBezier]
}
