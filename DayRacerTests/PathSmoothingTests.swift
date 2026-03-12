import Testing
@testable import DayRacer
import Foundation

// MARK: - Douglas-Peucker Tests

@Suite("DouglasPeucker")
struct DouglasPeuckerTests {

    @Test("Preserves start and end points")
    func preservesEndpoints() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 5, y: 1),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 15, y: 0.5),
            CGPoint(x: 20, y: 0),
        ]
        let simplified = DouglasPeucker.simplify(points, epsilon: 2.0)
        #expect(simplified.first == points.first)
        #expect(simplified.last == points.last)
    }

    @Test("Reduces point count for noisy line")
    func reducesPoints() {
        // Roughly straight line with micro-jitter
        let points = (0..<50).map { i in
            CGPoint(x: CGFloat(i) * 2, y: CGFloat(sin(Double(i) * 0.1) * 0.5))
        }
        let simplified = DouglasPeucker.simplify(points, epsilon: 2.0)
        #expect(simplified.count < points.count)
        #expect(simplified.count >= 2)
    }

    @Test("Preserves sharp corners")
    func preservesSharpCorners() {
        // L-shaped path: sharp 90° turn should be preserved
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 0),
            CGPoint(x: 50, y: 50),
        ]
        let simplified = DouglasPeucker.simplify(points, epsilon: 2.0)
        #expect(simplified.count == 3)
    }

    @Test("Returns input unchanged for 2 points")
    func twoPoints() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]
        let simplified = DouglasPeucker.simplify(points, epsilon: 2.0)
        #expect(simplified.count == 2)
    }

    @Test("Returns input unchanged for 1 point")
    func singlePoint() {
        let points = [CGPoint(x: 5, y: 5)]
        let simplified = DouglasPeucker.simplify(points, epsilon: 2.0)
        #expect(simplified.count == 1)
    }

    @Test("Empty input returns empty output")
    func emptyInput() {
        let simplified = DouglasPeucker.simplify([], epsilon: 2.0)
        #expect(simplified.isEmpty)
    }

    @Test("Higher epsilon removes more points")
    func epsilonEffect() {
        let points = (0..<30).map { i in
            CGPoint(x: CGFloat(i) * 3, y: CGFloat(sin(Double(i) * 0.5) * 10))
        }
        let loose = DouglasPeucker.simplify(points, epsilon: 8.0)
        let tight = DouglasPeucker.simplify(points, epsilon: 1.0)
        #expect(loose.count <= tight.count)
    }

    @Test("Perpendicular distance is accurate")
    func perpendicularDistance() {
        // Point directly above midpoint of horizontal line
        let dist = DouglasPeucker.perpendicularDistance(
            point: CGPoint(x: 5, y: 10),
            lineStart: CGPoint(x: 0, y: 0),
            lineEnd: CGPoint(x: 10, y: 0)
        )
        #expect(abs(dist - 10.0) < 0.001)
    }

    @Test("Perpendicular distance to degenerate line (zero-length)")
    func degenerateLine() {
        let dist = DouglasPeucker.perpendicularDistance(
            point: CGPoint(x: 3, y: 4),
            lineStart: CGPoint(x: 0, y: 0),
            lineEnd: CGPoint(x: 0, y: 0)
        )
        #expect(abs(dist - 5.0) < 0.001)
    }
}

// MARK: - Catmull-Rom Tests

@Suite("CatmullRom")
struct CatmullRomTests {

    @Test("Output has more points than input")
    func densifiesPoints() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 20, y: 30),
            CGPoint(x: 50, y: 20),
            CGPoint(x: 80, y: 40),
        ]
        let smoothed = CatmullRom.interpolate(points, samplesPerSegment: 10)
        #expect(smoothed.count > points.count)
    }

    @Test("Passes through control points")
    func passesThrough() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 30, y: 50),
            CGPoint(x: 60, y: 10),
            CGPoint(x: 100, y: 60),
        ]
        let smoothed = CatmullRom.interpolate(points, samplesPerSegment: 10)

        // First and last points should match exactly
        #expect(abs(smoothed.first!.x - points.first!.x) < 0.01)
        #expect(abs(smoothed.first!.y - points.first!.y) < 0.01)
        #expect(abs(smoothed.last!.x - points.last!.x) < 0.01)
        #expect(abs(smoothed.last!.y - points.last!.y) < 0.01)
    }

    @Test("Preserves endpoints with 2 points")
    func twoPointsEndpoints() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)]
        let smoothed = CatmullRom.interpolate(points, samplesPerSegment: 5)
        #expect(abs(smoothed.first!.x - 0) < 0.01)
        #expect(abs(smoothed.last!.x - 100) < 0.01)
    }

    @Test("Single point returns unchanged")
    func singlePoint() {
        let points = [CGPoint(x: 42, y: 42)]
        let smoothed = CatmullRom.interpolate(points)
        #expect(smoothed.count == 1)
        #expect(smoothed[0] == points[0])
    }

    @Test("Empty returns empty")
    func emptyInput() {
        let smoothed = CatmullRom.interpolate([])
        #expect(smoothed.isEmpty)
    }

    @Test("Output is smoother than input (angle changes are smaller)")
    func smoothness() {
        // Zigzag input
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 20, y: 40),
            CGPoint(x: 40, y: 0),
            CGPoint(x: 60, y: 40),
            CGPoint(x: 80, y: 0),
        ]
        let smoothed = CatmullRom.interpolate(points, samplesPerSegment: 10)
        let inputMaxAngle = maxAngleChange(points)
        let smoothedMaxAngle = maxAngleChange(smoothed)
        #expect(smoothedMaxAngle < inputMaxAngle)
    }

    @Test("Different alpha values produce different curves")
    func alphaEffect() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 30, y: 50),
            CGPoint(x: 60, y: 10),
            CGPoint(x: 100, y: 60),
        ]
        let uniform = CatmullRom.interpolate(points, alpha: 0.0, samplesPerSegment: 10)
        let centripetal = CatmullRom.interpolate(points, alpha: 0.5, samplesPerSegment: 10)

        // They should differ at interior points
        var different = false
        for i in 1..<min(uniform.count, centripetal.count) - 1 {
            if abs(uniform[i].x - centripetal[i].x) > 0.1 || abs(uniform[i].y - centripetal[i].y) > 0.1 {
                different = true
                break
            }
        }
        #expect(different)
    }

    private func maxAngleChange(_ points: [CGPoint]) -> CGFloat {
        guard points.count >= 3 else { return 0 }
        var maxAngle: CGFloat = 0
        for i in 1..<(points.count - 1) {
            let a = atan2(points[i].y - points[i-1].y, points[i].x - points[i-1].x)
            let b = atan2(points[i+1].y - points[i].y, points[i+1].x - points[i].x)
            var diff = abs(b - a)
            if diff > .pi { diff = 2 * .pi - diff }
            maxAngle = max(maxAngle, diff)
        }
        return maxAngle
    }
}

// MARK: - PathSmoother Pipeline Tests

@Suite("PathSmoother")
struct PathSmootherTests {

    @Test("Pipeline preserves start and end points")
    func preservesEndpoints() {
        let raw = [
            CGPoint(x: 10, y: 100),
            CGPoint(x: 12, y: 95),
            CGPoint(x: 15, y: 85),
            CGPoint(x: 20, y: 70),
            CGPoint(x: 25, y: 55),
            CGPoint(x: 30, y: 40),
            CGPoint(x: 35, y: 30),
            CGPoint(x: 40, y: 20),
        ]
        let (_, smoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .tight90)
        #expect(abs(smoothed.first!.x - raw.first!.x) < 1.0)
        #expect(abs(smoothed.first!.y - raw.first!.y) < 1.0)
        #expect(abs(smoothed.last!.x - raw.last!.x) < 1.0)
        #expect(abs(smoothed.last!.y - raw.last!.y) < 1.0)
    }

    @Test("Simplified has fewer points than raw")
    func simplificationReduces() {
        // Noisy path with many points
        let raw = (0..<100).map { i in
            CGPoint(
                x: CGFloat(i) * 2 + CGFloat.random(in: -0.5...0.5),
                y: CGFloat(i) * 3 + CGFloat.random(in: -0.5...0.5)
            )
        }
        let (simplified, _) = PathSmoother.smooth(rawPoints: raw, cornerType: .sweeper)
        #expect(simplified.count < raw.count)
    }

    @Test("Smoothed has more points than simplified")
    func interpolationDensifies() {
        let raw = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 20),
            CGPoint(x: 30, y: 10),
            CGPoint(x: 50, y: 30),
            CGPoint(x: 70, y: 5),
        ]
        let (simplified, smoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .chicane)
        #expect(smoothed.count > simplified.count)
    }

    @Test("Hairpin uses lower alpha than default")
    func hairpinAlpha() {
        // We verify indirectly: hairpin and sweeper should produce different smoothed results
        // for the same input, because they use different alpha values
        let raw = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 20, y: 40),
            CGPoint(x: 50, y: 30),
            CGPoint(x: 80, y: 60),
        ]
        let (_, hairpinSmoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .hairpin)
        let (_, sweeperSmoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .sweeper)

        var different = false
        for i in 1..<min(hairpinSmoothed.count, sweeperSmoothed.count) - 1 {
            if abs(hairpinSmoothed[i].x - sweeperSmoothed[i].x) > 0.01 {
                different = true
                break
            }
        }
        #expect(different)
    }

    @Test("Two points returns two points")
    func twoPointInput() {
        let raw = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]
        let (simplified, smoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .esses)
        #expect(simplified.count == 2)
        #expect(smoothed.count >= 2)
    }

    @Test("Single point returns single point")
    func singlePointInput() {
        let raw = [CGPoint(x: 5, y: 5)]
        let (simplified, smoothed) = PathSmoother.smooth(rawPoints: raw, cornerType: .tight90)
        #expect(simplified.count == 1)
        #expect(smoothed.count == 1)
    }

    @Test("Empty input returns empty")
    func emptyInput() {
        let (simplified, smoothed) = PathSmoother.smooth(rawPoints: [], cornerType: .hairpin)
        #expect(simplified.isEmpty)
        #expect(smoothed.isEmpty)
    }
}
