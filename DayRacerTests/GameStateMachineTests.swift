import Testing
@testable import DayRacer
import Foundation

@Suite("GameStateMachine")
struct GameStateMachineTests {

    // MARK: - Helpers

    private func makeTrack() -> GeneratedTrack {
        let generator = TrackGenerator()
        return generator.generate(for: Date(timeIntervalSince1970: 1_700_000_000))
    }

    private func makeCornerResult(index: Int, grade: CornerGrade = .fast, cornerType: CornerType = .hairpin) -> CornerResult {
        CornerResult(
            cornerIndex: index,
            grade: grade,
            deviationScore: grade == .crash ? -1 : 10,
            timePenalty: grade.penalty * cornerType.weight,
            swipePath: SwipePath(rawPoints: [])
        )
    }

    /// Advance a fresh state machine through a full corner cycle (autodrive → swipe → evaluate → playback → post)
    private func advanceThroughCorner(
        _ sm: inout GameStateMachine,
        index: Int,
        grade: CornerGrade = .fast,
        crashed: Bool = false
    ) throws {
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        let cornerType = sm.currentCorner?.corner.type ?? .hairpin
        let result = makeCornerResult(index: index, grade: grade, cornerType: cornerType)
        if crashed {
            try sm.send(.crashDetected(result))
            try sm.send(.crashHoldComplete)
        } else {
            try sm.send(.finishedDrawing(result))
        }
        try sm.send(.gradeCardComplete)
        try sm.send(.carPlaybackComplete)
        try sm.send(.postCornerComplete)
    }

    // MARK: - Initial State

    @Test("Initial state is idle")
    func initialState() {
        let sm = GameStateMachine()
        #expect(sm.state == .idle)
        #expect(sm.currentCornerIndex == 0)
        #expect(sm.cornerResults.isEmpty)
        #expect(sm.generatedTrack == nil)
        #expect(sm.lapTime == nil)
    }

    // MARK: - Happy Path Transitions

    @Test("idle → loading via startRace")
    func idleToLoading() throws {
        var sm = GameStateMachine()
        let newState = try sm.send(.startRace)
        #expect(newState == .loading)
        #expect(sm.state == .loading)
    }

    @Test("loading → autodriving via trackReady")
    func loadingToAutodriving() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        let track = makeTrack()
        let newState = try sm.send(.trackReady(track))
        #expect(newState == .autodriving)
        #expect(sm.generatedTrack != nil)
        #expect(sm.currentCornerIndex == 0)
    }

    @Test("autodriving → awaitingSwipe via reachedCorner")
    func autodrivingToAwaiting() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        let newState = try sm.send(.reachedCorner)
        #expect(newState == .awaitingSwipe)
    }

    @Test("awaitingSwipe → drawing via beganDrawing")
    func awaitingToDrawing() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        let newState = try sm.send(.beganDrawing)
        #expect(newState == .drawing)
    }

    @Test("drawing → evaluating via finishedDrawing")
    func drawingToEvaluating() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        let result = makeCornerResult(index: 0)
        let newState = try sm.send(.finishedDrawing(result))
        #expect(newState == .evaluating)
        #expect(sm.cornerResults.count == 1)
    }

    @Test("evaluating → carPlayback via gradeCardComplete")
    func evaluatingToCarPlayback() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        try sm.send(.finishedDrawing(makeCornerResult(index: 0)))
        let newState = try sm.send(.gradeCardComplete)
        #expect(newState == .carPlayback)
    }

    @Test("carPlayback → postCorner via carPlaybackComplete")
    func carPlaybackToPostCorner() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        try sm.send(.finishedDrawing(makeCornerResult(index: 0)))
        try sm.send(.gradeCardComplete)
        let newState = try sm.send(.carPlaybackComplete)
        #expect(newState == .postCorner)
    }

    @Test("postCorner → autodriving when more corners remain")
    func postCornerToAutodriving() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        try sm.send(.finishedDrawing(makeCornerResult(index: 0)))
        try sm.send(.gradeCardComplete)
        try sm.send(.carPlaybackComplete)
        let newState = try sm.send(.postCornerComplete)
        #expect(newState == .autodriving)
        #expect(sm.currentCornerIndex == 1)
    }

    // MARK: - Crash Path

    @Test("drawing → crashed via crashDetected")
    func drawingToCrashed() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        let result = makeCornerResult(index: 0, grade: .crash)
        let newState = try sm.send(.crashDetected(result))
        #expect(newState == .crashed)
        #expect(sm.cornerResults.count == 1)
        #expect(sm.cornerResults[0].grade == .crash)
    }

    @Test("crashed → evaluating via crashHoldComplete")
    func crashedToEvaluating() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        try sm.send(.crashDetected(makeCornerResult(index: 0, grade: .crash)))
        let newState = try sm.send(.crashHoldComplete)
        #expect(newState == .evaluating)
    }

    @Test("Full crash path: drawing → crashed → evaluating → carPlayback → postCorner")
    func fullCrashPath() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try advanceThroughCorner(&sm, index: 0, grade: .crash, crashed: true)
        #expect(sm.state == .autodriving)
        #expect(sm.currentCornerIndex == 1)
        #expect(sm.cornerResults.count == 1)
    }

    // MARK: - Full Game Loop

    @Test("Complete 5-corner game reaches finished then results")
    func fullGameLoop() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))

        // Corners 0-3: advance normally
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i)
            #expect(sm.state == .autodriving)
            #expect(sm.currentCornerIndex == i + 1)
        }

        // Corner 4 (last): should go to finished
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        let result = makeCornerResult(index: 4)
        try sm.send(.finishedDrawing(result))
        try sm.send(.gradeCardComplete)
        try sm.send(.carPlaybackComplete)
        let postState = try sm.send(.postCornerComplete)
        #expect(postState == .finished)
        #expect(sm.cornerResults.count == 5)
        #expect(sm.lapTime != nil)
    }

    @Test("finished auto-transitions to results on any event")
    func finishedToResults() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i)
        }
        try advanceThroughCorner(&sm, index: 4)
        // State should be finished, send dismiss to get to results
        #expect(sm.state == .finished)
        let newState = try sm.send(.dismiss)
        #expect(newState == .results)
    }

    @Test("results → idle via dismiss")
    func resultsToIdle() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i)
        }
        try advanceThroughCorner(&sm, index: 4)
        #expect(sm.state == .finished)
        try sm.send(.dismiss) // finished → results
        let newState = try sm.send(.dismiss) // results → idle
        #expect(newState == .idle)
        #expect(sm.generatedTrack == nil)
        #expect(sm.cornerResults.isEmpty)
        #expect(sm.lapTime == nil)
    }

    @Test("Lap time is computed when reaching finished state")
    func lapTimeComputed() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i)
        }
        try advanceThroughCorner(&sm, index: 4)
        #expect(sm.state == .finished)
        #expect(sm.lapTime != nil)
        #expect(sm.lapTime! > 0)
    }

    // MARK: - Mixed Grades Game

    @Test("Game with mixed grades and crashes computes correct lap time")
    func mixedGradesGame() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))

        // Corner 0: fast
        try advanceThroughCorner(&sm, index: 0, grade: .fast)
        // Corner 1: crash
        try advanceThroughCorner(&sm, index: 1, grade: .crash, crashed: true)
        // Corner 2: average
        try advanceThroughCorner(&sm, index: 2, grade: .average)
        // Corner 3: slow
        try advanceThroughCorner(&sm, index: 3, grade: .slow)
        // Corner 4: fast
        try advanceThroughCorner(&sm, index: 4, grade: .fast)

        #expect(sm.state == .finished)
        #expect(sm.cornerResults.count == 5)
        #expect(sm.lapTime != nil)
        // Should be above par (60s) due to crash and slow grades
        #expect(sm.lapTime! > LapTimeCalculator.parTime)
    }

    // MARK: - Invalid Transitions

    @Test("startRace from non-idle state throws")
    func startRaceFromWrongState() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.startRace)
        }
    }

    @Test("beganDrawing from idle throws")
    func beganDrawingFromIdle() {
        var sm = GameStateMachine()
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.beganDrawing)
        }
    }

    @Test("finishedDrawing from non-drawing state throws")
    func finishedDrawingFromWrongState() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.finishedDrawing(makeCornerResult(index: 0)))
        }
    }

    @Test("crashDetected from non-drawing state throws")
    func crashFromWrongState() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        // awaitingSwipe — crash before drawing
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.crashDetected(makeCornerResult(index: 0, grade: .crash)))
        }
    }

    @Test("reachedCorner from drawing throws")
    func reachedCornerFromDrawing() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.reachedCorner)
        }
    }

    @Test("gradeCardComplete from non-evaluating state throws")
    func gradeCardFromWrongState() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.gradeCardComplete)
        }
    }

    @Test("dismiss from drawing state throws")
    func dismissFromDrawing() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        try sm.send(.reachedCorner)
        try sm.send(.beganDrawing)
        #expect(throws: GameStateMachine.TransitionError.self) {
            try sm.send(.dismiss)
        }
    }

    // MARK: - Corner Tracking

    @Test("Corner index increments correctly through game")
    func cornerIndexTracking() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        #expect(sm.currentCornerIndex == 0)

        try advanceThroughCorner(&sm, index: 0)
        #expect(sm.currentCornerIndex == 1)

        try advanceThroughCorner(&sm, index: 1)
        #expect(sm.currentCornerIndex == 2)

        try advanceThroughCorner(&sm, index: 2)
        #expect(sm.currentCornerIndex == 3)

        try advanceThroughCorner(&sm, index: 3)
        #expect(sm.currentCornerIndex == 4)
    }

    @Test("Corner results accumulate correctly")
    func cornerResultsAccumulation() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))

        for i in 0..<3 {
            try advanceThroughCorner(&sm, index: i)
            #expect(sm.cornerResults.count == i + 1)
        }
    }

    @Test("currentCorner returns correct generated corner")
    func currentCornerQuery() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        let track = makeTrack()
        try sm.send(.trackReady(track))

        #expect(sm.currentCorner?.corner.index == 0)
        try advanceThroughCorner(&sm, index: 0)
        #expect(sm.currentCorner?.corner.index == 1)
    }

    @Test("isLastCorner is true only at corner 4")
    func isLastCornerQuery() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))

        for i in 0..<4 {
            #expect(!sm.isLastCorner)
            try advanceThroughCorner(&sm, index: i)
        }
        #expect(sm.isLastCorner)
    }

    @Test("cornerCount is 5")
    func cornerCountValue() {
        let sm = GameStateMachine()
        #expect(sm.cornerCount == 5)
        #expect(GameStateMachine.cornerCount == 5)
    }

    // MARK: - Reset on New Game

    @Test("trackReady resets state for new game")
    func trackReadyResetsState() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        // Play through some corners
        try advanceThroughCorner(&sm, index: 0)
        try advanceThroughCorner(&sm, index: 1)
        #expect(sm.cornerResults.count == 2)
        #expect(sm.currentCornerIndex == 2)

        // Complete game, go to results, dismiss, start new game
        try advanceThroughCorner(&sm, index: 2)
        try advanceThroughCorner(&sm, index: 3)
        try advanceThroughCorner(&sm, index: 4)
        try sm.send(.dismiss) // finished → results
        try sm.send(.dismiss) // results → idle
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))

        #expect(sm.currentCornerIndex == 0)
        #expect(sm.cornerResults.isEmpty)
        #expect(sm.lapTime == nil)
    }

    // MARK: - Valid Events Query

    @Test("validEvents returns correct events for each state")
    func validEventsQuery() throws {
        var sm = GameStateMachine()
        #expect(sm.validEvents.contains("startRace"))

        try sm.send(.startRace)
        #expect(sm.validEvents.contains("trackReady"))

        try sm.send(.trackReady(makeTrack()))
        #expect(sm.validEvents.contains("reachedCorner"))

        try sm.send(.reachedCorner)
        #expect(sm.validEvents.contains("beganDrawing"))

        try sm.send(.beganDrawing)
        #expect(sm.validEvents.contains("finishedDrawing"))
        #expect(sm.validEvents.contains("crashDetected"))
    }

    // MARK: - All Fast Lap Time

    @Test("All-fast game produces lap time below par")
    func allFastLapTime() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i, grade: .fast)
        }
        try advanceThroughCorner(&sm, index: 4, grade: .fast)
        #expect(sm.lapTime! < LapTimeCalculator.parTime)
    }

    @Test("All-crash game produces lap time well above par")
    func allCrashLapTime() throws {
        var sm = GameStateMachine()
        try sm.send(.startRace)
        try sm.send(.trackReady(makeTrack()))
        for i in 0..<4 {
            try advanceThroughCorner(&sm, index: i, grade: .crash, crashed: true)
        }
        try advanceThroughCorner(&sm, index: 4, grade: .crash, crashed: true)
        #expect(sm.lapTime! > LapTimeCalculator.parTime + 10)
    }
}
