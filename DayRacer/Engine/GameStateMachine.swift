import Foundation

/// Events that drive state transitions in the game state machine.
enum GameEvent: Sendable {
    case startRace
    case trackReady(GeneratedTrack)
    case reachedCorner
    case beganDrawing
    case finishedDrawing(CornerResult)
    case crashDetected(CornerResult)
    case crashHoldComplete
    case gradeCardComplete
    case carPlaybackComplete
    case postCornerComplete
    case dismiss
}

/// Pure-logic state machine for the game loop. Zero UI imports.
/// Enforces valid transitions, tracks corner progress, accumulates results.
struct GameStateMachine: Sendable {

    private(set) var state: GameState = .idle
    private(set) var currentCornerIndex: Int = 0
    private(set) var cornerResults: [CornerResult] = []
    private(set) var generatedTrack: GeneratedTrack?
    private(set) var lapTime: Double?

    static let cornerCount = 5

    // MARK: - Errors

    enum TransitionError: Error, Equatable {
        case invalidTransition(from: GameState, event: String)
        case cornerIndexMismatch(expected: Int, got: Int)
    }

    // MARK: - Transition

    /// Process an event and transition to the next valid state.
    /// Throws `TransitionError.invalidTransition` if the event is not valid for the current state.
    /// Throws `TransitionError.cornerIndexMismatch` if a result's cornerIndex doesn't match.
    @discardableResult
    mutating func send(_ event: GameEvent) throws -> GameState {
        try validateCornerIndex(for: event)
        let newState = try nextState(for: event)
        state = newState
        applyEffects(for: event)

        // Auto-chain: finished computes lap time and immediately transitions to results
        if state == .finished {
            computeLapTime()
            state = .results
        }

        return state
    }

    // MARK: - Valid Transitions

    private func nextState(for event: GameEvent) throws -> GameState {
        switch (state, event) {
        case (.idle, .startRace):
            return .loading

        case (.loading, .trackReady):
            return .autodriving

        case (.autodriving, .reachedCorner):
            return .awaitingSwipe

        case (.awaitingSwipe, .beganDrawing):
            return .drawing

        case (.drawing, .finishedDrawing):
            return .evaluating

        case (.drawing, .crashDetected):
            return .crashed

        case (.crashed, .crashHoldComplete):
            return .evaluating

        case (.evaluating, .gradeCardComplete):
            return .carPlayback

        case (.carPlayback, .carPlaybackComplete):
            return .postCorner

        case (.postCorner, .postCornerComplete):
            if currentCornerIndex >= Self.cornerCount - 1 {
                return .finished
            } else {
                return .autodriving
            }

        case (.results, .dismiss):
            return .idle

        default:
            throw TransitionError.invalidTransition(
                from: state,
                event: String(describing: event)
            )
        }
    }

    // MARK: - Validation

    private func validateCornerIndex(for event: GameEvent) throws {
        switch event {
        case .finishedDrawing(let result):
            guard result.cornerIndex == currentCornerIndex else {
                throw TransitionError.cornerIndexMismatch(
                    expected: currentCornerIndex, got: result.cornerIndex
                )
            }
        case .crashDetected(let result):
            guard result.cornerIndex == currentCornerIndex else {
                throw TransitionError.cornerIndexMismatch(
                    expected: currentCornerIndex, got: result.cornerIndex
                )
            }
        default:
            break
        }
    }

    // MARK: - Side Effects

    private mutating func applyEffects(for event: GameEvent) {
        switch event {
        case .trackReady(let track):
            generatedTrack = track
            currentCornerIndex = 0
            cornerResults = []
            lapTime = nil

        case .finishedDrawing(let result), .crashDetected(let result):
            cornerResults.append(result)

        case .postCornerComplete:
            // Increment corner index when moving to next corner.
            // When going to finished (last corner), index stays — it's no longer used.
            if state == .autodriving {
                currentCornerIndex += 1
            }

        case .dismiss where state == .idle:
            // Only reset when actually returning to idle (results → idle)
            generatedTrack = nil
            currentCornerIndex = 0
            cornerResults = []
            lapTime = nil

        default:
            break
        }
    }

    private mutating func computeLapTime() {
        guard let track = generatedTrack else { return }
        let types = track.generatedCorners.map { $0.corner.type }
        lapTime = LapTimeCalculator.calculate(
            cornerResults: cornerResults,
            cornerTypes: types
        )
    }

    // MARK: - Queries

    var currentCorner: GeneratedCorner? {
        guard let track = generatedTrack,
              currentCornerIndex < track.generatedCorners.count else { return nil }
        return track.generatedCorners[currentCornerIndex]
    }

    var isLastCorner: Bool {
        currentCornerIndex >= Self.cornerCount - 1
    }

    var cornerCount: Int {
        Self.cornerCount
    }

    /// All valid events for the current state.
    var validEvents: [String] {
        switch state {
        case .idle: return ["startRace"]
        case .loading: return ["trackReady"]
        case .autodriving: return ["reachedCorner"]
        case .awaitingSwipe: return ["beganDrawing"]
        case .drawing: return ["finishedDrawing", "crashDetected"]
        case .crashed: return ["crashHoldComplete"]
        case .evaluating: return ["gradeCardComplete"]
        case .carPlayback: return ["carPlaybackComplete"]
        case .postCorner: return ["postCornerComplete"]
        case .finished: return ["(auto-transitions to results)"]
        case .results: return ["dismiss"]
        }
    }
}
