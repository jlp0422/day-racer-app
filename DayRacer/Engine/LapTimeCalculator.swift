import Foundation

enum LapTimeCalculator {

    /// Base par time (seconds) — represents an "all average" lap.
    static let parTime: Double = 60.0

    /// Calculates total lap time from corner results.
    /// Par time = all average grades. All fast ≈ 3s faster. All crash ≈ 25s slower.
    static func calculate(cornerResults: [CornerResult]) -> Double {
        let totalPenalty = cornerResults.reduce(0.0) { $0 + $1.timePenalty }
        let baselinePenalty = baselineAveragePenalty(for: cornerResults)
        return parTime + (totalPenalty - baselinePenalty)
    }

    /// Baseline penalty if all corners were "average" — used to center par time.
    static func baselineAveragePenalty(for cornerResults: [CornerResult]) -> Double {
        // This would need the corner types to compute properly.
        // For simplicity, we use a fixed average baseline.
        // 5 corners × average penalty (0.4) × average weight (~1.2) ≈ 2.4
        GameConstants.Scoring.averagePenalty * 5.0 * 1.2
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
