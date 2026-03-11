import Foundation

enum GameState: String, Sendable {
    case idle
    case loading
    case autodriving
    case awaitingSwipe
    case drawing
    case crashed
    case evaluating
    case carPlayback
    case postCorner
    case finished
    case results
}
