import Foundation

struct CornerResult: Codable, Sendable {
    let cornerIndex: Int
    let grade: CornerGrade
    let deviationScore: Double
    let timePenalty: Double
    let swipePath: SwipePath
}
