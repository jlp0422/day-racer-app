import Foundation

enum LapTimeCalculator {

    /// Base par time (seconds) — represents an "all average" lap.
    static let parTime: Double = 60.0

    /// Calculates total lap time from corner results and their corresponding corner types.
    /// Par time = all average grades. All fast ≈ 3s faster. All crash ≈ 25s slower.
    static func calculate(cornerResults: [CornerResult], cornerTypes: [CornerType]) -> Double {
        let totalPenalty = cornerResults.reduce(0.0) { $0 + $1.timePenalty }
        let baselinePenalty = cornerTypes.reduce(0.0) { sum, type in
            sum + GameConstants.Scoring.averagePenalty * type.weight
        }
        return parTime + (totalPenalty - baselinePenalty)
    }

    /// Convenience: calculate from individual grades and corner types.
    static func calculate(
        grades: [(grade: CornerGrade, cornerType: CornerType)]
    ) -> Double {
        let totalPenalty = grades.reduce(0.0) { sum, entry in
            sum + entry.grade.penalty * entry.cornerType.weight
        }
        let baselinePenalty = grades.reduce(0.0) { sum, entry in
            sum + GameConstants.Scoring.averagePenalty * entry.cornerType.weight
        }
        return parTime + (totalPenalty - baselinePenalty)
    }
}
