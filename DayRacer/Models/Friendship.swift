import Foundation

enum FriendshipStatus: String, Codable, Sendable {
    case pending
    case accepted
    case declined
}

struct Friendship: Identifiable, Codable, Sendable {
    let id: UUID
    let requesterId: String
    let accepterId: String?
    let status: FriendshipStatus
    let inviteCode: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        requesterId: String,
        accepterId: String? = nil,
        status: FriendshipStatus = .pending,
        inviteCode: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.requesterId = requesterId
        self.accepterId = accepterId
        self.status = status
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }
}
