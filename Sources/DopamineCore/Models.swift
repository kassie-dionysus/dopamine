import Foundation

/// Shared Swift domain models used across the engine, UI module, and tests.
public enum MetricID: String, CaseIterable, Codable, Sendable {
    case focus
    case momentum
    case progress
}

public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
}

public enum ProjectStatus: String, Codable, Sendable {
    case active
    case archived
}

public struct Scores: Codable, Equatable, Sendable {
    public var focus: Int
    public var momentum: Int
    public var progress: Int

    public init(focus: Int, momentum: Int, progress: Int) {
        self.focus = focus
        self.momentum = momentum
        self.progress = progress
    }
}

public struct ScoreBreakdownItem: Codable, Equatable, Sendable {
    public var score: Int
    public var drivers: [String]
    public var detractors: [String]
    public var improve: String

    public init(score: Int, drivers: [String], detractors: [String], improve: String) {
        self.score = score
        self.drivers = drivers
        self.detractors = detractors
        self.improve = improve
    }
}

public struct ScoreBreakdown: Codable, Equatable, Sendable {
    public var focus: ScoreBreakdownItem
    public var momentum: ScoreBreakdownItem
    public var progress: ScoreBreakdownItem

    public init(focus: ScoreBreakdownItem, momentum: ScoreBreakdownItem, progress: ScoreBreakdownItem) {
        self.focus = focus
        self.momentum = momentum
        self.progress = progress
    }
}

public struct Project: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var colorHex: String
    public var status: ProjectStatus
    public var momentum: Double
    public var hardness: Double
    public var timeRequired: Double
    public var feasibility: Double
    public var centroid: [String: Double]
    public var messageCount: Int
    public var lastTouchedAt: Date

    public init(
        id: String,
        name: String,
        colorHex: String,
        status: ProjectStatus,
        momentum: Double,
        hardness: Double,
        timeRequired: Double,
        feasibility: Double,
        centroid: [String: Double],
        messageCount: Int,
        lastTouchedAt: Date
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.status = status
        self.momentum = momentum
        self.hardness = hardness
        self.timeRequired = timeRequired
        self.feasibility = feasibility
        self.centroid = centroid
        self.messageCount = messageCount
        self.lastTouchedAt = lastTouchedAt
    }
}

public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var role: MessageRole
    public var content: String
    public var createdAt: Date
    public var projectID: String

    public init(id: String, role: MessageRole, content: String, createdAt: Date, projectID: String) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.projectID = projectID
    }
}

public struct SessionState: Codable, Equatable, Sendable {
    public var sessionID: String
    public var startedAt: Date
    public var updatedAt: Date
    public var selectedProjectID: String?
    public var projects: [Project]
    public var messages: [ChatMessage]
    public var planUnits: Int
    public var completedUnits: Int

    public init(
        sessionID: String,
        startedAt: Date,
        updatedAt: Date,
        selectedProjectID: String?,
        projects: [Project],
        messages: [ChatMessage],
        planUnits: Int,
        completedUnits: Int
    ) {
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.selectedProjectID = selectedProjectID
        self.projects = projects
        self.messages = messages
        self.planUnits = planUnits
        self.completedUnits = completedUnits
    }
}

public struct ArchiveEvent: Codable, Equatable, Sendable {
    public var archivedProjectID: String
    public var activatedProjectID: String

    public init(archivedProjectID: String, activatedProjectID: String) {
        self.archivedProjectID = archivedProjectID
        self.activatedProjectID = activatedProjectID
    }
}

public struct ChatResponse: Codable, Equatable, Sendable {
    public var assistantMessage: ChatMessage
    public var messages: [ChatMessage]
    public var scores: Scores
    public var scoreBreakdown: ScoreBreakdown
    public var selectedProjectID: String?
    public var activeProjects: [Project]
    public var archivedProjects: [Project]
    public var archiveEvent: ArchiveEvent?

    public init(
        assistantMessage: ChatMessage,
        messages: [ChatMessage],
        scores: Scores,
        scoreBreakdown: ScoreBreakdown,
        selectedProjectID: String?,
        activeProjects: [Project],
        archivedProjects: [Project],
        archiveEvent: ArchiveEvent?
    ) {
        self.assistantMessage = assistantMessage
        self.messages = messages
        self.scores = scores
        self.scoreBreakdown = scoreBreakdown
        self.selectedProjectID = selectedProjectID
        self.activeProjects = activeProjects
        self.archivedProjects = archivedProjects
        self.archiveEvent = archiveEvent
    }
}

public struct PendingAssistantTurn: Codable, Equatable, Sendable {
    public var userMessage: ChatMessage
    public var messages: [ChatMessage]
    public var scores: Scores
    public var scoreBreakdown: ScoreBreakdown
    public var selectedProjectID: String?
    public var activeProjects: [Project]
    public var archivedProjects: [Project]
    public var archiveEvent: ArchiveEvent?
    public var localReply: String

    public init(
        userMessage: ChatMessage,
        messages: [ChatMessage],
        scores: Scores,
        scoreBreakdown: ScoreBreakdown,
        selectedProjectID: String?,
        activeProjects: [Project],
        archivedProjects: [Project],
        archiveEvent: ArchiveEvent?,
        localReply: String
    ) {
        self.userMessage = userMessage
        self.messages = messages
        self.scores = scores
        self.scoreBreakdown = scoreBreakdown
        self.selectedProjectID = selectedProjectID
        self.activeProjects = activeProjects
        self.archivedProjects = archivedProjects
        self.archiveEvent = archiveEvent
        self.localReply = localReply
    }
}

public struct BarState: Codable, Equatable, Sendable {
    public var id: MetricID
    public var value: Double
    public var colorHex: String
    public var revealed: Bool

    public init(id: MetricID, value: Double, colorHex: String, revealed: Bool) {
        self.id = id
        self.value = value
        self.colorHex = colorHex
        self.revealed = revealed
    }
}
