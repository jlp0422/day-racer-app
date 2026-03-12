import Testing
@testable import DayRacer
import Foundation

@Suite("CrashDetector")
struct CrashDetectorTests {

    // MARK: - Line Intersection

    @Test("Crossing segments intersect")
    func crossingSegments() {
        let a = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 10))
        let b = LineSegment(start: CGPoint(x: 10, y: 0), end: CGPoint(x: 0, y: 10))
        let result = CrashDetector.lineIntersection(a, b)
        #expect(result != nil)
        #expect(abs(result!.x - 5) < 0.01)
        #expect(abs(result!.y - 5) < 0.01)
    }

    @Test("Parallel segments don't intersect")
    func parallelSegments() {
        let a = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
        let b = LineSegment(start: CGPoint(x: 0, y: 5), end: CGPoint(x: 10, y: 5))
        #expect(CrashDetector.lineIntersection(a, b) == nil)
    }

    @Test("Non-overlapping segments don't intersect")
    func nonOverlapping() {
        let a = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 5, y: 0))
        let b = LineSegment(start: CGPoint(x: 6, y: -1), end: CGPoint(x: 6, y: 1))
        #expect(CrashDetector.lineIntersection(a, b) == nil)
    }

    @Test("T-intersection at endpoint")
    func tIntersection() {
        let a = LineSegment(start: CGPoint(x: 0, y: 5), end: CGPoint(x: 10, y: 5))
        let b = LineSegment(start: CGPoint(x: 5, y: 0), end: CGPoint(x: 5, y: 5))
        let result = CrashDetector.lineIntersection(a, b)
        #expect(result != nil)
        #expect(abs(result!.x - 5) < 0.01)
        #expect(abs(result!.y - 5) < 0.01)
    }

    @Test("Near-miss (1pt gap) doesn't intersect")
    func nearMiss() {
        let a = LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
        let b = LineSegment(start: CGPoint(x: 5, y: 1), end: CGPoint(x: 5, y: 10))
        #expect(CrashDetector.lineIntersection(a, b) == nil)
    }

    // MARK: - AABB Culling

    @Test("Overlapping AABBs detected")
    func aabbOverlap() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 5, y: 5, width: 10, height: 10)
        #expect(CrashDetector.aabbOverlap(a, b))
    }

    @Test("Non-overlapping AABBs rejected")
    func aabbNoOverlap() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 20, y: 20, width: 10, height: 10)
        #expect(!CrashDetector.aabbOverlap(a, b))
    }

    @Test("Adjacent AABBs overlap (touching edges)")
    func aabbTouching() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 10, y: 0, width: 10, height: 10)
        #expect(CrashDetector.aabbOverlap(a, b))
    }

    // MARK: - Full Detection

    @Test("Path crossing boundary detects crash")
    func pathCrossesBoundary() {
        let boundary = TrackBoundary(
            points: [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 50)],
            side: .outer,
            barrierStyle: .concrete
        )
        let emptyBoundary = TrackBoundary(points: [], side: .inner, barrierStyle: .concrete)
        let pathPoints = [CGPoint(x: 50, y: 0), CGPoint(x: 50, y: 100)]

        let result = CrashDetector.detect(
            pathPoints: pathPoints,
            innerBoundary: emptyBoundary,
            outerBoundary: boundary
        )
        #expect(result != nil)
        #expect(abs(result!.crashPoint.x - 50) < 0.01)
        #expect(abs(result!.crashPoint.y - 50) < 0.01)
    }

    @Test("Path inside boundaries doesn't crash")
    func pathInsideBoundaries() {
        let inner = TrackBoundary(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100)],
            side: .inner,
            barrierStyle: .tireStack
        )
        let outer = TrackBoundary(
            points: [CGPoint(x: 100, y: 0), CGPoint(x: 100, y: 100)],
            side: .outer,
            barrierStyle: .tireStack
        )
        // Path going straight down the middle
        let pathPoints = [CGPoint(x: 50, y: 0), CGPoint(x: 50, y: 50), CGPoint(x: 50, y: 100)]

        let result = CrashDetector.detect(
            pathPoints: pathPoints,
            innerBoundary: inner,
            outerBoundary: outer
        )
        #expect(result == nil)
    }

    @Test("Empty path doesn't crash")
    func emptyPath() {
        let boundary = TrackBoundary(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)],
            side: .outer,
            barrierStyle: .armco
        )
        let result = CrashDetector.detect(
            pathPoints: [],
            innerBoundary: boundary,
            outerBoundary: boundary
        )
        #expect(result == nil)
    }

    @Test("Single point path doesn't crash")
    func singlePoint() {
        let boundary = TrackBoundary(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)],
            side: .outer,
            barrierStyle: .armco
        )
        let result = CrashDetector.detect(
            pathPoints: [CGPoint(x: 50, y: 50)],
            innerBoundary: boundary,
            outerBoundary: boundary
        )
        #expect(result == nil)
    }

    @Test("Crash returns first intersection point")
    func firstIntersection() {
        // Two boundary segments, path crosses both — should get first
        let boundary = TrackBoundary(
            points: [CGPoint(x: 0, y: 30), CGPoint(x: 100, y: 30)],
            side: .outer,
            barrierStyle: .concrete
        )
        let boundary2 = TrackBoundary(
            points: [CGPoint(x: 0, y: 70), CGPoint(x: 100, y: 70)],
            side: .inner,
            barrierStyle: .concrete
        )
        let pathPoints = [CGPoint(x: 50, y: 0), CGPoint(x: 50, y: 50), CGPoint(x: 50, y: 100)]

        let result = CrashDetector.detect(
            pathPoints: pathPoints,
            innerBoundary: boundary2,
            outerBoundary: boundary
        )
        #expect(result != nil)
        // Should hit the y=30 boundary first
        #expect(abs(result!.crashPoint.y - 30) < 0.01)
    }
}
