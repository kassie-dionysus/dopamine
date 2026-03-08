import Foundation
import DopamineCore

/// SwiftUI view model that binds UI interactions to the in-process Dopamine engine.
@MainActor
public final class DopamineViewModel: ObservableObject {
    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var activeProjects: [Project] = []
    @Published public private(set) var archivedProjects: [Project] = []
    @Published public private(set) var scores = Scores(focus: 50, momentum: 50, progress: 50)
    @Published public var selectedProjectID: String?
    @Published public var input = ""
    @Published public var revealedMetric: MetricID?

    private let engine: DopamineEngine
    private let sessionID: String
    private var archivedCursor: Int?

    public init(engine: DopamineEngine = DopamineEngine(), sessionID: String = "ios-session") {
        self.engine = engine
        self.sessionID = sessionID
        start()
    }

    public var bars: [BarState] {
        [
            BarState(id: .focus, value: Double(scores.focus), colorHex: "#00b4d8", revealed: revealedMetric == .focus),
            BarState(id: .momentum, value: Double(scores.momentum), colorHex: "#ff9f1c", revealed: revealedMetric == .momentum),
            BarState(id: .progress, value: Double(scores.progress), colorHex: "#2a9d8f", revealed: revealedMetric == .progress)
        ]
    }

    public var visibleMessages: [ChatMessage] {
        guard let selectedProjectID else {
            return messages
        }
        return messages.filter { $0.projectID == selectedProjectID }
    }

    public func start() {
        let response = engine.start(sessionID: sessionID)
        apply(response: response)
        selectedProjectID = response.activeProjects.first?.id
        if response.archivedProjects.count > DopamineEngine.archivedPageSize {
            archivedCursor = DopamineEngine.archivedPageSize
            archivedProjects = Array(response.archivedProjects.prefix(DopamineEngine.archivedPageSize))
        }
    }

    public func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let response = engine.postMessage(sessionID: sessionID, content: trimmed)
        input = ""
        apply(response: response)
    }

    public func finishSession() {
        let response = engine.finish(sessionID: sessionID)
        apply(response: response)
    }

    public func selectProject(_ projectID: String) {
        let result = engine.switchProject(sessionID: sessionID, projectID: projectID)
        activeProjects = result.active
        archivedProjects = result.archived
        selectedProjectID = projectID
    }

    public func renameProject(projectID: String, name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = engine.renameProject(sessionID: sessionID, projectID: projectID, name: name)
        activeProjects = activeProjects.map { project in
            var updated = project
            if updated.id == projectID { updated.name = name }
            return updated
        }
        archivedProjects = archivedProjects.map { project in
            var updated = project
            if updated.id == projectID { updated.name = name }
            return updated
        }
    }

    public func reassignMessage(messageID: String, projectID: String) {
        guard engine.reassignMessage(sessionID: sessionID, messageID: messageID, projectID: projectID) else { return }
        messages = messages.map { message in
            var updated = message
            if updated.id == messageID { updated.projectID = projectID }
            return updated
        }
    }

    public func loadArchivedIfNeeded(currentProjectID: String) {
        guard let cursor = archivedCursor,
              archivedProjects.last?.id == currentProjectID else {
            return
        }

        let page = engine.archivedPage(sessionID: sessionID, cursor: cursor)
        archivedProjects.append(contentsOf: page.projects)
        archivedCursor = page.nextCursor
    }

    public func toggleMetric(_ metric: MetricID) {
        revealedMetric = (revealedMetric == metric) ? nil : metric
    }

    private func apply(response: ChatResponse) {
        messages = response.messages
        activeProjects = response.activeProjects
        archivedProjects = response.archivedProjects
        scores = response.scores
    }
}
