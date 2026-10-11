import Foundation

public struct CommandResponse: Codable, Sendable {
    public let success: Bool
    public let type: String?
    public let app: String?
    public let message: String?
    public let speech: String?
    public let timestamp: String?
    public let command: String?
}

public struct BatteryInfo: Codable, Sendable {
    public let status: String?
    public let percent: String?
    public let power_source: String?
}

public struct SystemStatus: Codable, Sendable {
    public let status: String?
    public let assistant_name: String?
    public let platform: String?
    public let platform_release: String?
    public let hostname: String?
    public let uptime_seconds: Int?
    public let battery: BatteryInfo?
    public let speech_recognition_available: Bool?
    public let timestamp: String?
}

public struct AppItem: Identifiable, Hashable, Sendable {
    public var id: String { key }
    public let key: String
    public let name: String
    public let category: String
    public let icon: String // SF Symbol name
    public let isInstalled: Bool
    public let bundlePath: String?

    public init(key: String, name: String, category: String, icon: String, isInstalled: Bool = false, bundlePath: String? = nil) {
        self.key = key
        self.name = name
        self.category = category
        self.icon = icon
        self.isInstalled = isInstalled
        self.bundlePath = bundlePath
    }
}

public struct WebsiteItem: Identifiable, Hashable, Sendable {
    public var id: String { key }
    public let key: String
    public let title: String
    public let url: String
    public let category: String
    public let badge: String
    public let icon: String
}

public struct HistoryEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let command: String
    public let message: String
    public let speech: String?
    public let timestamp: String
    public let success: Bool

    public init(id: UUID = UUID(), command: String, message: String, speech: String? = nil, timestamp: String, success: Bool) {
        self.id = id
        self.command = command
        self.message = message
        self.speech = speech
        self.timestamp = timestamp
        self.success = success
    }
}

// MARK: - Business & Executive Models

public enum BusinessPriority: String, CaseIterable, Codable, Sendable {
    case p0 = "P0 - Critical"
    case p1 = "P1 - High Strategic"
    case p2 = "P2 - Operational"
    case p3 = "P3 - Delegated"

    public var badgeColorHex: String {
        switch self {
        case .p0: return "#EF4444" // Red
        case .p1: return "#F59E0B" // Amber
        case .p2: return "#3B82F6" // Blue
        case .p3: return "#10B981" // Emerald
        }
    }

    public var shortLabel: String {
        switch self {
        case .p0: return "P0"
        case .p1: return "P1"
        case .p2: return "P2"
        case .p3: return "P3"
        }
    }
}

public struct BusinessTask: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var priority: BusinessPriority
    public var category: String
    public var isCompleted: Bool
    public var dueDate: String
    public var createdAt: String

    public init(
        id: UUID = UUID(),
        title: String,
        priority: BusinessPriority = .p1,
        category: String = "Strategy",
        isCompleted: Bool = false,
        dueDate: String = "Today",
        createdAt: String = ""
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt.isEmpty ? DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short) : createdAt
    }
}

public enum EmailTone: String, CaseIterable, Identifiable, Codable, Sendable {
    case executiveDirect = "Executive Direct"
    case clientProposal = "Client Proposal"
    case gentleFollowUp = "Gentle Follow-Up"
    case projectEscalation = "Project Escalation"
    case meetingInvite = "Meeting Request"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .executiveDirect: return "bolt.shield.fill"
        case .clientProposal: return "briefcase.fill"
        case .gentleFollowUp: return "clock.arrow.circlepath"
        case .projectEscalation: return "exclamationmark.triangle.fill"
        case .meetingInvite: return "calendar.badge.plus"
        }
    }
}

public struct ExecutiveEmailDraft: Identifiable, Codable, Sendable {
    public let id: UUID
    public var recipient: String
    public var subject: String
    public var body: String
    public var tone: EmailTone
    public var timestamp: String

    public init(
        id: UUID = UUID(),
        recipient: String,
        subject: String,
        body: String,
        tone: EmailTone = .executiveDirect,
        timestamp: String = ""
    ) {
        self.id = id
        self.recipient = recipient
        self.subject = subject
        self.body = body
        self.tone = tone
        self.timestamp = timestamp.isEmpty ? DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium) : timestamp
    }
}

public struct MeetingAgenda: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var durationMinutes: Int
    public var objective: String
    public var topics: [String]
    public var expectedOutcomes: [String]

    public init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        objective: String,
        topics: [String],
        expectedOutcomes: [String]
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.objective = objective
        self.topics = topics
        self.expectedOutcomes = expectedOutcomes
    }
}

public struct DailyExecutiveBrief: Identifiable, Codable, Sendable {
    public let id: UUID
    public let dateString: String
    public let greeting: String
    public let focusQuote: String
    public let pendingP0Count: Int
    public let pendingTotalCount: Int
    public let strategicDeliverables: [String]
    public let marketSentiment: String
    public let speechBrief: String

    public init(
        id: UUID = UUID(),
        dateString: String,
        greeting: String,
        focusQuote: String,
        pendingP0Count: Int,
        pendingTotalCount: Int,
        strategicDeliverables: [String],
        marketSentiment: String,
        speechBrief: String
    ) {
        self.id = id
        self.dateString = dateString
        self.greeting = greeting
        self.focusQuote = focusQuote
        self.pendingP0Count = pendingP0Count
        self.pendingTotalCount = pendingTotalCount
        self.strategicDeliverables = strategicDeliverables
        self.marketSentiment = marketSentiment
        self.speechBrief = speechBrief
    }
}

