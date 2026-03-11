import Foundation

enum CornerType: String, Codable, CaseIterable, Sendable {
    case hairpin
    case doubleApex
    case tight90
    case chicane
    case esses
    case sweeper

    var weight: Double {
        switch self {
        case .hairpin: return GameConstants.Scoring.CornerWeight.hairpin
        case .doubleApex: return GameConstants.Scoring.CornerWeight.doubleApex
        case .tight90: return GameConstants.Scoring.CornerWeight.tight90
        case .chicane: return GameConstants.Scoring.CornerWeight.chicane
        case .esses: return GameConstants.Scoring.CornerWeight.esses
        case .sweeper: return GameConstants.Scoring.CornerWeight.sweeper
        }
    }

    var trackWidth: CGFloat {
        switch self {
        case .hairpin: return GameConstants.Track.Width.hairpin
        case .doubleApex: return GameConstants.Track.Width.doubleApex
        case .tight90: return GameConstants.Track.Width.tight90
        case .chicane: return GameConstants.Track.Width.chicane
        case .esses: return GameConstants.Track.Width.esses
        case .sweeper: return GameConstants.Track.Width.sweeper
        }
    }

    var gravelWidth: CGFloat {
        switch self {
        case .hairpin: return GameConstants.Track.GravelWidth.hairpin
        case .doubleApex: return GameConstants.Track.GravelWidth.doubleApex
        case .tight90: return GameConstants.Track.GravelWidth.tight90
        case .chicane: return GameConstants.Track.GravelWidth.chicane
        case .esses: return GameConstants.Track.GravelWidth.esses
        case .sweeper: return GameConstants.Track.GravelWidth.sweeper
        }
    }

    var bezierSegmentCount: Int {
        switch self {
        case .hairpin: return 2
        case .doubleApex: return 2
        case .tight90: return 1
        case .chicane: return 2
        case .esses: return 3
        case .sweeper: return 1
        }
    }

    var barrierStyle: BarrierStyle {
        switch self {
        case .hairpin, .doubleApex: return .tireStack
        case .tight90, .esses: return .concrete
        case .chicane, .sweeper: return .armco
        }
    }
}

enum CornerGrade: String, Codable, Sendable {
    case fast
    case average
    case slow
    case crash

    var penalty: Double {
        switch self {
        case .fast: return GameConstants.Scoring.fastPenalty
        case .average: return GameConstants.Scoring.averagePenalty
        case .slow: return GameConstants.Scoring.slowPenalty
        case .crash: return GameConstants.Scoring.crashPenalty
        }
    }

    var emoji: String {
        switch self {
        case .fast: return "🟢"
        case .average: return "🟡"
        case .slow: return "🔴"
        case .crash: return "💀"
        }
    }
}

enum BoundarySide: String, Codable, Sendable {
    case inner
    case outer
}

enum BarrierStyle: String, Codable, Sendable {
    case concrete
    case tireStack
    case armco
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
