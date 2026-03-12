import Foundation

struct RaceResult: Identifiable, Codable, Sendable {
    let id: UUID
    let deviceId: String
    let trackDate: Date
    let lapTime: Double
    let cornerResults: [CornerResult]
    let emojiPattern: String
    let percentile: Double?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        deviceId: String,
        trackDate: Date,
        lapTime: Double,
        cornerResults: [CornerResult],
        emojiPattern: String? = nil,
        percentile: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.deviceId = deviceId
        self.trackDate = trackDate
        self.lapTime = lapTime
        self.cornerResults = cornerResults
        self.emojiPattern = emojiPattern ?? cornerResults.map(\.grade.emoji).joined()
        self.percentile = percentile
        self.createdAt = createdAt
    }
}
