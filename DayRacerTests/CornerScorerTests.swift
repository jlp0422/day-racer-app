import Testing
@testable import DayRacer
import Foundation

@Suite("CornerScorer")
struct CornerScorerTests {

    // MARK: - Grade from Deviation

    @Test("Fast grade for deviation < 14")
    func fastGrade() {
        #expect(CornerScorer.gradeFromDeviation(10) == .fast)
        #expect(CornerScorer.gradeFromDeviation(13.9) == .fast)
    }

    @Test("Average grade for deviation 14-30")
    func averageGrade() {
        #expect(CornerScorer.gradeFromDeviation(14) == .average)
        #expect(CornerScorer.gradeFromDeviation(20) == .average)
        #expect(CornerScorer.gradeFromDeviation(29.9) == .average)
    }

    @Test("Slow grade for deviation >= 30")
    func slowGrade() {
        #expect(CornerScorer.gradeFromDeviation(30) == .slow)
        #expect(CornerScorer.gradeFromDeviation(50) == .slow)
    }

    // MARK: - Crash Override

    @Test("Crash overrides any deviation score")
    func crashOverride() {
        let idealLine = makeIdealLine()
        let perfectPath = idealLine.points

        let (grade, _, penalty) = CornerScorer.score(
            smoothedPath: perfectPath,
            idealLine: idealLine,
            cornerType: .hairpin,
            didCrash: true
        )
        #expect(grade == .crash)
        #expect(penalty == GameConstants.Scoring.crashPenalty * CornerType.hairpin.weight)
    }

    // MARK: - Perfect Path

    @Test("Path on ideal line scores fast")
    func perfectPath() {
        let idealLine = makeIdealLine()

        let (grade, deviation, _) = CornerScorer.score(
            smoothedPath: idealLine.points,
            idealLine: idealLine,
            cornerType: .sweeper,
            didCrash: false
        )
        #expect(grade == .fast)
        #expect(deviation < GameConstants.Scoring.fastThreshold)
    }

    // MARK: - Offset Path

    @Test("Significantly offset path scores slow")
    func offsetPath() {
        let idealLine = makeIdealLine()
        // Shift all points 40pt to the right
        let offsetPath = idealLine.points.map { CGPoint(x: $0.x + 40, y: $0.y) }

        let (grade, deviation, _) = CornerScorer.score(
            smoothedPath: offsetPath,
            idealLine: idealLine,
            cornerType: .tight90,
            didCrash: false
        )
        #expect(grade == .slow)
        #expect(deviation >= GameConstants.Scoring.averageThreshold)
    }

    // MARK: - Penalty Calculation

    @Test("Crash penalty equals crash penalty × corner weight", arguments: CornerType.allCases)
    func crashPenaltyCalculation(type: CornerType) {
        let expected = CornerGrade.crash.penalty * type.weight
        let idealLine = makeIdealLine()

        let (_, _, penalty) = CornerScorer.score(
            smoothedPath: idealLine.points,
            idealLine: idealLine,
            cornerType: type,
            didCrash: true
        )
        #expect(abs(penalty - expected) < 0.001)
    }

    @Test("Crash deviation is -1 sentinel")
    func crashDeviationSentinel() {
        let idealLine = makeIdealLine()
        let (_, deviation, _) = CornerScorer.score(
            smoothedPath: idealLine.points,
            idealLine: idealLine,
            cornerType: .tight90,
            didCrash: true
        )
        #expect(deviation == -1)
    }

    @Test("Fast penalty is zero regardless of corner type", arguments: CornerType.allCases)
    func fastPenaltyIsZero(type: CornerType) {
        let idealLine = makeIdealLine()
        let (grade, _, penalty) = CornerScorer.score(
            smoothedPath: idealLine.points,
            idealLine: idealLine,
            cornerType: type,
            didCrash: false
        )
        #expect(grade == .fast)
        #expect(penalty == 0)
    }

    // MARK: - Apex Weighting

    @Test("Apex-weighted deviation differs from uniform for off-apex paths")
    func apexWeightingEffect() {
        let idealLine = makeIdealLineWithApex()
        // Path that's accurate at entry/exit but drifts at apex
        var path = idealLine.points
        let apexRegionStart = path.count / 3
        let apexRegionEnd = 2 * path.count / 3
        for i in apexRegionStart..<apexRegionEnd {
            path[i] = CGPoint(x: path[i].x + 20, y: path[i].y)
        }

        let weightedDev = CornerScorer.apexWeightedAverageDeviation(
            smoothedPath: path,
            idealLine: idealLine
        )
        // Should be higher than a simple average because apex region is weighted 2×
        // and that's where the offset is
        #expect(weightedDev > 5)
    }

    // MARK: - All 6 Corner Types

    @Test("All corner types can be scored", arguments: CornerType.allCases)
    func allCornerTypes(type: CornerType) {
        let idealLine = makeIdealLine()
        let (grade, _, _) = CornerScorer.score(
            smoothedPath: idealLine.points,
            idealLine: idealLine,
            cornerType: type,
            didCrash: false
        )
        #expect(grade == .fast)
    }

    // MARK: - Even Sampling

    @Test("Even sampling produces correct count")
    func evenSampling() {
        let points = (0..<100).map { i in CGPoint(x: CGFloat(i), y: 0) }
        let samples = CornerScorer.evenlySpacedSamples(from: points, count: 60)
        #expect(samples.count == 60)
    }

    @Test("Even sampling preserves endpoints")
    func evenSamplingEndpoints() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 100, y: 0),
        ]
        let samples = CornerScorer.evenlySpacedSamples(from: points, count: 20)
        #expect(abs(samples.first!.x - 0) < 0.01)
        #expect(abs(samples.last!.x - 100) < 0.01)
    }

    // MARK: - Empty/Edge Cases

    @Test("Empty smoothed path scores slow")
    func emptyPath() {
        let idealLine = makeIdealLine()
        let (grade, _, _) = CornerScorer.score(
            smoothedPath: [],
            idealLine: idealLine,
            cornerType: .esses,
            didCrash: false
        )
        #expect(grade == .slow)
    }

    // MARK: - Helpers

    private func makeIdealLine() -> CornerPath {
        let points = (0..<80).map { (i: Int) -> CGPoint in
            CGPoint(x: 195.0 + CGFloat(i) / 2.0, y: 784.0 - CGFloat(i) * 8.0)
        }
        return CornerPath(
            points: points,
            entryPoint: points.first!,
            apexPoints: [points[40]],
            exitPoint: points.last!,
            bezierSegments: []
        )
    }

    private func makeIdealLineWithApex() -> CornerPath {
        let points = (0..<80).map { (i: Int) -> CGPoint in
            CGPoint(x: 195.0 + CGFloat(i) / 2.0, y: 784.0 - CGFloat(i) * 8.0)
        }
        return CornerPath(
            points: points,
            entryPoint: points.first!,
            apexPoints: [points[40]],
            exitPoint: points.last!,
            bezierSegments: []
        )
    }
}
