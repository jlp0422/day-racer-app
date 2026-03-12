import Foundation

enum CornerScorer {

    private static let sampleCount = 60

    /// Scores a user's smoothed path against the ideal racing line.
    /// Uses apex-weighted average perpendicular distance.
    /// - Parameters:
    ///   - smoothedPath: User's smoothed swipe path points
    ///   - idealLine: The corner's ideal racing line
    ///   - cornerType: Used to determine crash penalty weight
    ///   - didCrash: Whether the path crashed into a boundary
    /// - Returns: (grade, deviationScore, timePenalty)
    static func score(
        smoothedPath: [CGPoint],
        idealLine: CornerPath,
        cornerType: CornerType,
        didCrash: Bool
    ) -> (grade: CornerGrade, deviationScore: Double, timePenalty: Double) {
        if didCrash {
            let penalty = GameConstants.Scoring.crashPenalty * cornerType.weight
            return (.crash, 0, penalty)
        }

        guard !smoothedPath.isEmpty, !idealLine.points.isEmpty else {
            let penalty = GameConstants.Scoring.slowPenalty * cornerType.weight
            return (.slow, Double(GameConstants.Scoring.averageThreshold), penalty)
        }

        let deviationScore = apexWeightedAverageDeviation(
            smoothedPath: smoothedPath,
            idealLine: idealLine
        )

        let grade = gradeFromDeviation(deviationScore)
        let penalty = grade.penalty * cornerType.weight

        return (grade, deviationScore, penalty)
    }

    /// Computes apex-weighted average perpendicular distance.
    /// Points near apex zones are weighted 2× to reward clipping the apex.
    static func apexWeightedAverageDeviation(
        smoothedPath: [CGPoint],
        idealLine: CornerPath
    ) -> Double {
        let idealPoints = idealLine.points
        guard !idealPoints.isEmpty, !smoothedPath.isEmpty else { return 0 }

        // Sample N evenly-spaced points along ideal line
        let samples = evenlySpacedSamples(from: idealPoints, count: sampleCount)
        let apexIndices = findApexSampleIndices(
            samples: samples,
            apexPoints: idealLine.apexPoints
        )

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        for (i, idealPt) in samples.enumerated() {
            let closestDist = closestDistance(from: idealPt, to: smoothedPath)
            let weight = apexWeight(sampleIndex: i, apexIndices: apexIndices, totalSamples: sampleCount)
            weightedSum += Double(closestDist) * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 0 }
        return weightedSum / totalWeight
    }

    /// Determines grade from deviation score.
    static func gradeFromDeviation(_ deviation: Double) -> CornerGrade {
        if deviation < GameConstants.Scoring.fastThreshold {
            return .fast
        } else if deviation < GameConstants.Scoring.averageThreshold {
            return .average
        }
        return .slow
    }

    // MARK: - Helpers

    /// Evenly sample N points from a polyline.
    static func evenlySpacedSamples(from points: [CGPoint], count: Int) -> [CGPoint] {
        guard points.count >= 2, count >= 2 else { return points }

        // Compute cumulative arc length
        var cumLengths: [CGFloat] = [0]
        for i in 1..<points.count {
            let d = hypot(points[i].x - points[i-1].x, points[i].y - points[i-1].y)
            cumLengths.append(cumLengths.last! + d)
        }
        let totalLength = cumLengths.last!
        guard totalLength > 0 else { return [points[0]] }

        var samples: [CGPoint] = []
        var segIndex = 0

        for i in 0..<count {
            let targetDist = totalLength * CGFloat(i) / CGFloat(count - 1)

            // Find the segment containing this distance
            while segIndex < cumLengths.count - 2 && cumLengths[segIndex + 1] < targetDist {
                segIndex += 1
            }

            let segStart = cumLengths[segIndex]
            let segEnd = cumLengths[segIndex + 1]
            let segLen = segEnd - segStart

            let t: CGFloat = segLen > 0 ? (targetDist - segStart) / segLen : 0
            let p = CGPoint(
                x: points[segIndex].x + t * (points[segIndex + 1].x - points[segIndex].x),
                y: points[segIndex].y + t * (points[segIndex + 1].y - points[segIndex].y)
            )
            samples.append(p)
        }
        return samples
    }

    /// Find which sample indices are closest to apex points.
    private static func findApexSampleIndices(
        samples: [CGPoint],
        apexPoints: [CGPoint]
    ) -> Set<Int> {
        var indices = Set<Int>()
        for apex in apexPoints {
            var bestIdx = 0
            var bestDist = CGFloat.infinity
            for (i, sample) in samples.enumerated() {
                let d = hypot(sample.x - apex.x, sample.y - apex.y)
                if d < bestDist {
                    bestDist = d
                    bestIdx = i
                }
            }
            indices.insert(bestIdx)
        }
        return indices
    }

    /// Returns weight for a sample point. Points within 20% of an apex get 2× weight.
    private static func apexWeight(
        sampleIndex: Int,
        apexIndices: Set<Int>,
        totalSamples: Int
    ) -> Double {
        let apexRadius = max(1, totalSamples / 5) // 20% of total samples
        for apexIdx in apexIndices {
            if abs(sampleIndex - apexIdx) <= apexRadius {
                return 2.0
            }
        }
        return 1.0
    }

    /// Closest distance from a point to any point on a polyline.
    private static func closestDistance(from point: CGPoint, to polyline: [CGPoint]) -> CGFloat {
        guard polyline.count >= 2 else {
            if let first = polyline.first {
                return hypot(point.x - first.x, point.y - first.y)
            }
            return .infinity
        }

        var minDist = CGFloat.infinity
        for i in 0..<(polyline.count - 1) {
            let seg = LineSegment(start: polyline[i], end: polyline[i + 1])
            let d = BoundaryProximityChecker.distanceToSegment(point: point, segment: seg)
            minDist = min(minDist, d)
        }
        return minDist
    }
}
