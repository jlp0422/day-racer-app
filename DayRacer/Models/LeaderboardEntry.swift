import Foundation

struct LeaderboardEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let deviceId: String
    let displayName: String
    let avatarEmoji: String
    let lapTime: Double
    let emojiPattern: String
    let rank: Int
    let percentile: Double

    init(
        id: UUID = UUID(),
        deviceId: String,
        displayName: String,
        avatarEmoji: String,
        lapTime: Double,
        emojiPattern: String,
        rank: Int,
        percentile: Double
    ) {
        self.id = id
        self.deviceId = deviceId
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.lapTime = lapTime
        self.emojiPattern = emojiPattern
        self.rank = rank
        self.percentile = percentile
    }
}
