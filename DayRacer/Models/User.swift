import Foundation

struct User: Identifiable, Codable, Sendable {
    let deviceId: String
    var displayName: String
    var avatarEmoji: String
    var streak: Int
    var bestLap: Double?
    let createdAt: Date

    var id: String { deviceId }

    init(
        deviceId: String,
        displayName: String,
        avatarEmoji: String = "🏎️",
        streak: Int = 0,
        bestLap: Double? = nil,
        createdAt: Date = .now
    ) {
        self.deviceId = deviceId
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.streak = streak
        self.bestLap = bestLap
        self.createdAt = createdAt
    }
}
