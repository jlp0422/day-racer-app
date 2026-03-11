import Foundation

struct Track: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let name: String
    let corners: [Corner]
    let seed: UInt64

    init(
        id: UUID = UUID(),
        date: Date = .now,
        name: String,
        corners: [Corner],
        seed: UInt64
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.corners = corners
        self.seed = seed
    }
}
