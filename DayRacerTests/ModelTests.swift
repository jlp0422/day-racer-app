import Testing
@testable import DayRacer
import Foundation

// MARK: - CornerType Tests

@Suite("CornerType")
struct CornerTypeTests {
    @Test("All 6 corner types exist")
    func allCases() {
        #expect(CornerType.allCases.count == 6)
    }

    @Test("Weights match spec", arguments: [
        (CornerType.hairpin, 1.8),
        (.doubleApex, 1.5),
        (.tight90, 1.3),
        (.chicane, 1.2),
        (.esses, 1.0),
        (.sweeper, 0.8),
    ])
    func weights(type: CornerType, expected: Double) {
        #expect(type.weight == expected)
    }

    @Test("Track widths match spec", arguments: [
        (CornerType.hairpin, 85.0 as CGFloat),
        (.doubleApex, 75.0),
        (.tight90, 70.0),
        (.chicane, 65.0),
        (.esses, 60.0),
        (.sweeper, 55.0),
    ])
    func trackWidths(type: CornerType, expected: CGFloat) {
        #expect(type.trackWidth == expected)
    }

    @Test("Bezier segment counts match spec", arguments: [
        (CornerType.hairpin, 2),
        (.doubleApex, 2),
        (.tight90, 1),
        (.chicane, 3),
        (.esses, 3),
        (.sweeper, 1),
    ])
    func bezierSegments(type: CornerType, expected: Int) {
        #expect(type.bezierSegmentCount == expected)
    }
}

// MARK: - CornerGrade Tests

@Suite("CornerGrade")
struct CornerGradeTests {
    @Test("Penalties match spec", arguments: [
        (CornerGrade.fast, 0.0),
        (.average, 0.4),
        (.slow, 1.5),
        (.crash, 3.5),
    ])
    func penalties(grade: CornerGrade, expected: Double) {
        #expect(grade.penalty == expected)
    }

    @Test("Each grade has an emoji")
    func emojis() {
        for grade in [CornerGrade.fast, .average, .slow, .crash] {
            #expect(!grade.emoji.isEmpty)
        }
    }

    @Test("Crash emoji is skull")
    func crashEmoji() {
        #expect(CornerGrade.crash.emoji == "💀")
    }
}

// MARK: - Geometry Tests

@Suite("Geometry")
struct GeometryTests {
    @Test("LineSegment bounding box")
    func lineSegmentBoundingBox() {
        let seg = LineSegment(start: CGPoint(x: 10, y: 20), end: CGPoint(x: 50, y: 5))
        let bb = seg.boundingBox
        #expect(bb.origin.x == 10)
        #expect(bb.origin.y == 5)
        #expect(bb.width == 40)
        #expect(bb.height == 15)
    }

    @Test("CubicBezier endpoints")
    func cubicBezierEndpoints() {
        let bezier = CubicBezier(
            p0: CGPoint(x: 0, y: 0),
            p1: CGPoint(x: 10, y: 30),
            p2: CGPoint(x: 40, y: 30),
            p3: CGPoint(x: 50, y: 0)
        )
        let start = bezier.point(at: 0)
        let end = bezier.point(at: 1)
        #expect(abs(start.x - 0) < 0.001)
        #expect(abs(start.y - 0) < 0.001)
        #expect(abs(end.x - 50) < 0.001)
        #expect(abs(end.y - 0) < 0.001)
    }

    @Test("CubicBezier midpoint is reasonable")
    func cubicBezierMidpoint() {
        let bezier = CubicBezier(
            p0: CGPoint(x: 0, y: 0),
            p1: CGPoint(x: 0, y: 100),
            p2: CGPoint(x: 100, y: 100),
            p3: CGPoint(x: 100, y: 0)
        )
        let mid = bezier.point(at: 0.5)
        #expect(mid.x == 50)
        #expect(mid.y == 75)
    }
}

// MARK: - TrackBoundary Tests

@Suite("TrackBoundary")
struct TrackBoundaryTests {
    @Test("Segments computed from points")
    func segmentsFromPoints() {
        let boundary = TrackBoundary(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 10, y: 10)],
            side: .outer,
            barrierStyle: .concrete
        )
        #expect(boundary.segments.count == 2)
        #expect(boundary.segments[0].start == CGPoint(x: 0, y: 0))
        #expect(boundary.segments[0].end == CGPoint(x: 10, y: 0))
        #expect(boundary.segments[1].start == CGPoint(x: 10, y: 0))
        #expect(boundary.segments[1].end == CGPoint(x: 10, y: 10))
    }

    @Test("Empty points produces no segments")
    func emptyPoints() {
        let boundary = TrackBoundary(points: [], side: .inner, barrierStyle: .armco)
        #expect(boundary.segments.isEmpty)
    }

    @Test("Single point produces no segments")
    func singlePoint() {
        let boundary = TrackBoundary(
            points: [CGPoint(x: 5, y: 5)],
            side: .inner,
            barrierStyle: .tireStack
        )
        #expect(boundary.segments.isEmpty)
    }
}

// MARK: - SwipePath Tests

@Suite("SwipePath")
struct SwipePathTests {
    @Test("Default init has no crash")
    func defaultNoCrash() {
        let path = SwipePath(rawPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)])
        #expect(!path.didCrash)
        #expect(path.crashPoint == nil)
        #expect(path.crashSegmentIndex == nil)
        #expect(path.simplifiedPoints.isEmpty)
        #expect(path.smoothedPoints.isEmpty)
    }

    @Test("Crash path records crash data")
    func crashPath() {
        let crashPt = CGPoint(x: 25, y: 25)
        let path = SwipePath(
            rawPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 25, y: 25)],
            didCrash: true,
            crashPoint: crashPt,
            crashSegmentIndex: 3
        )
        #expect(path.didCrash)
        #expect(path.crashPoint == crashPt)
        #expect(path.crashSegmentIndex == 3)
    }
}

// MARK: - RaceResult Tests

@Suite("RaceResult")
struct RaceResultTests {
    @Test("Emoji pattern auto-generated from corner grades")
    func emojiPattern() {
        let cornerResults = [
            CornerResult(cornerIndex: 0, grade: .fast, deviationScore: 5, timePenalty: 0,
                         swipePath: SwipePath(rawPoints: [])),
            CornerResult(cornerIndex: 1, grade: .average, deviationScore: 20, timePenalty: 0.4,
                         swipePath: SwipePath(rawPoints: [])),
            CornerResult(cornerIndex: 2, grade: .crash, deviationScore: 0, timePenalty: 3.5,
                         swipePath: SwipePath(rawPoints: [], didCrash: true)),
            CornerResult(cornerIndex: 3, grade: .slow, deviationScore: 35, timePenalty: 1.5,
                         swipePath: SwipePath(rawPoints: [])),
            CornerResult(cornerIndex: 4, grade: .fast, deviationScore: 8, timePenalty: 0,
                         swipePath: SwipePath(rawPoints: [])),
        ]
        let result = RaceResult(
            deviceId: "test-device",
            trackDate: .now,
            lapTime: 25.0,
            cornerResults: cornerResults
        )
        #expect(result.emojiPattern == "🟢🟡💀🔴🟢")
    }
}

// MARK: - User Tests

@Suite("User")
struct UserTests {
    @Test("Default values")
    func defaults() {
        let user = User(deviceId: "abc123", displayName: "Racer")
        #expect(user.avatarEmoji == "🏎️")
        #expect(user.streak == 0)
        #expect(user.bestLap == nil)
        #expect(user.id == "abc123")
    }
}

// MARK: - Friendship Tests

@Suite("Friendship")
struct FriendshipTests {
    @Test("Default status is pending")
    func defaultPending() {
        let f = Friendship(requesterId: "a", inviteCode: "ABC123")
        #expect(f.status == .pending)
        #expect(f.accepterId == nil)
    }
}

// MARK: - GameState Tests

@Suite("GameState")
struct GameStateTests {
    @Test("All 11 states exist")
    func allStates() {
        let states: [GameState] = [
            .idle, .loading, .autodriving, .awaitingSwipe, .drawing,
            .crashed, .evaluating, .carPlayback, .postCorner, .finished, .results,
        ]
        #expect(states.count == 11)
    }
}
