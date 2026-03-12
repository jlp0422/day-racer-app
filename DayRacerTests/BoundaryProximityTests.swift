import Testing
@testable import DayRacer
import Foundation

@Suite("BoundaryProximityChecker")
struct BoundaryProximityTests {

    @Test("Distance to horizontal segment is accurate")
    func horizontalSegmentDistance() {
        let seg = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
        let dist = BoundaryProximityChecker.distanceToSegment(
            point: CGPoint(x: 5, y: 7),
            segment: seg
        )
        #expect(abs(dist - 7.0) < 0.001)
    }

    @Test("Distance to segment endpoint")
    func endpointDistance() {
        let seg = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
        // Point beyond the segment end
        let dist = BoundaryProximityChecker.distanceToSegment(
            point: CGPoint(x: 15, y: 0),
            segment: seg
        )
        #expect(abs(dist - 5.0) < 0.001)
    }

    @Test("Distance to zero-length segment")
    func zeroLengthSegment() {
        let seg = LineSegment(start: CGPoint(x: 5, y: 5), end: CGPoint(x: 5, y: 5))
        let dist = BoundaryProximityChecker.distanceToSegment(
            point: CGPoint(x: 8, y: 9),
            segment: seg
        )
        #expect(abs(dist - 5.0) < 0.001)
    }

    @Test("Minimum distance to boundary")
    func minDistanceToBoundary() {
        let boundary = TrackBoundary(
            points: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0),
                CGPoint(x: 100, y: 100),
            ],
            side: .outer,
            barrierStyle: .concrete
        )
        // Point at (50, 10) — closest to the horizontal segment at y=0
        let dist = BoundaryProximityChecker.minimumDistance(
            from: CGPoint(x: 50, y: 10),
            to: boundary
        )
        #expect(abs(dist - 10.0) < 0.001)
    }

    @Test("Proximity level: safe")
    func safePRoximity() {
        let level = BoundaryProximityChecker.proximityLevel(distance: 20)
        #expect(level == .safe)
    }

    @Test("Proximity level: warning (< 8pt)")
    func warningProximity() {
        let level = BoundaryProximityChecker.proximityLevel(distance: 6)
        #expect(level == .warning)
    }

    @Test("Proximity level: danger (< 4pt)")
    func dangerProximity() {
        let level = BoundaryProximityChecker.proximityLevel(distance: 2)
        #expect(level == .danger)
    }

    @Test("Check returns both distance and level")
    func checkCombined() {
        let inner = TrackBoundary(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)],
            side: .inner,
            barrierStyle: .tireStack
        )
        let outer = TrackBoundary(
            points: [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 50)],
            side: .outer,
            barrierStyle: .tireStack
        )
        // Point at (50, 3) — 3pt from inner boundary
        let (dist, level) = BoundaryProximityChecker.check(
            point: CGPoint(x: 50, y: 3),
            innerBoundary: inner,
            outerBoundary: outer
        )
        #expect(abs(dist - 3.0) < 0.001)
        #expect(level == .danger)
    }
}
