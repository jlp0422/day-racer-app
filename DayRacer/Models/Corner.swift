import Foundation

enum CornerType: String, Codable, CaseIterable, Sendable {
    case hairpin
    case doubleApex
    case tight90
    case chicane
    case esses
    case sweeper
}

struct Corner: Identifiable, Codable, Sendable {
    let id: UUID
    let type: CornerType
    let index: Int

    init(id: UUID = UUID(), type: CornerType, index: Int) {
        self.id = id
        self.type = type
        self.index = index
    }
}
