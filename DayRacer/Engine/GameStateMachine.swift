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

    // MARK: - Transition

    enum TransitionError: Error, Equatable {
        case invalidTransition(from: GameState, event: String)
    }

    /// Process an event and transition to the next valid state.
    /// Throws `TransitionError.invalidTransition` if the event is not valid for the current state.
    @discardableResult
    mutating func send(_ event: GameEvent) throws -> GameState {
        let newState = try nextState(for: event)
        state = newState
        applyEffects(for: event)
        return newState
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

        case (.finished, _):
            // finished auto-transitions to results; accept dismiss as well
            return .results

        case (.results, .dismiss):
            return .idle

        default:
            throw TransitionError.invalidTransition(
                from: state,
                event: String(describing: event)
            )
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

        case .postCornerComplete where state == .autodriving:
            // Only increment when advancing to next corner (not when going to finished)
            currentCornerIndex += 1

        case .dismiss:
            generatedTrack = nil
            currentCornerIndex = 0
            cornerResults = []
            lapTime = nil

        default:
            break
        }

        // Auto-compute lap time when entering finished
        if state == .finished {
            computeLapTime()
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
        case .finished: return ["(auto-transition to results)"]
        case .results: return ["dismiss"]
        }
    }
}
