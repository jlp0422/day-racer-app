import XCTest
@testable import DayRacer

final class GameConstantsTests: XCTestCase {

    // MARK: - Scoring

    func testScoringGradeThresholds() {
        XCTAssertEqual(GameConstants.Scoring.fastThreshold, 14.0)
        XCTAssertEqual(GameConstants.Scoring.averageThreshold, 30.0)
    }

    func testScoringPenalties() {
        XCTAssertEqual(GameConstants.Scoring.fastPenalty, 0.0)
        XCTAssertEqual(GameConstants.Scoring.averagePenalty, 0.4)
        XCTAssertEqual(GameConstants.Scoring.slowPenalty, 1.5)
        XCTAssertEqual(GameConstants.Scoring.crashPenalty, 3.5)
    }

    func testCornerWeights() {
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.hairpin, 1.8)
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.doubleApex, 1.5)
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.tight90, 1.3)
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.chicane, 1.2)
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.esses, 1.0)
        XCTAssertEqual(GameConstants.Scoring.CornerWeight.sweeper, 0.8)
    }

    // MARK: - Track

    func testTrackWidths() {
        XCTAssertEqual(GameConstants.Track.Width.hairpin, 85)
        XCTAssertEqual(GameConstants.Track.Width.doubleApex, 75)
        XCTAssertEqual(GameConstants.Track.Width.tight90, 70)
        XCTAssertEqual(GameConstants.Track.Width.chicane, 65)
        XCTAssertEqual(GameConstants.Track.Width.esses, 60)
        XCTAssertEqual(GameConstants.Track.Width.sweeper, 55)
    }

    func testKerbDimensions() {
        XCTAssertEqual(GameConstants.Track.Kerb.width, 6)
        XCTAssertEqual(GameConstants.Track.Kerb.height, 4)
    }

    // MARK: - Input

    func testInputConstants() {
        XCTAssertEqual(GameConstants.Input.minDragDistance, 10)
        XCTAssertEqual(GameConstants.Input.deadzone, 40)
        XCTAssertEqual(GameConstants.Input.dpEpsilon, 2.0)
        XCTAssertEqual(GameConstants.Input.crAlpha, 0.5)
        XCTAssertEqual(GameConstants.Input.crAlphaHairpin, 0.3)
        XCTAssertEqual(GameConstants.Input.pointSampleThreshold, 3.0)
    }

    // MARK: - Timing

    func testTimingConstants() {
        XCTAssertEqual(GameConstants.Timing.autoDriveSpeed, 0.8)
        XCTAssertEqual(GameConstants.Timing.gradeCardDuration, 0.8)
        XCTAssertEqual(GameConstants.Timing.crashHoldDuration, 1.0)
        XCTAssertEqual(GameConstants.Timing.crashFlashCount, 3)
        XCTAssertEqual(GameConstants.Timing.crashFlashDuration, 0.3)
    }

    // MARK: - Rendering

    func testRenderingConstants() {
        XCTAssertEqual(GameConstants.Rendering.idealLineOpacity, 0.25)
        XCTAssertEqual(GameConstants.Rendering.trailWidth, 3.5)
        XCTAssertEqual(GameConstants.Rendering.trailOpacity, 0.7)
        XCTAssertEqual(GameConstants.Rendering.proximityWarning, 8.0)
        XCTAssertEqual(GameConstants.Rendering.proximityDanger, 4.0)
        XCTAssertEqual(GameConstants.Rendering.CarBody.width, 12)
        XCTAssertEqual(GameConstants.Rendering.CarBody.height, 22)
    }
}
