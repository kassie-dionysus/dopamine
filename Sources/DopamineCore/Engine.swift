import Foundation

/// In-memory Swift engine for session state, project routing, cap/archive policy, and replies.
public final class DopamineEngine {
    public static let activeProjectCap = 3
    public static let archivedPageSize = 12
    public static let newProjectThreshold = 0.18

    private static let projectColors = [
        "#1982c4", "#8ac926", "#ffca3a", "#ff595e", "#6a4c93", "#2ec4b6", "#fb5607", "#3a86ff"
    ]

    private var sessions: [String: SessionState] = [:]

    public init() {}

    public func start(sessionID: String) -> ChatResponse {
        var state = getOrCreateSession(sessionID: sessionID)
        let projectID = state.selectedProjectID ?? state.projects.first?.id ?? makeID(prefix: "proj")
        let assistantMessage = addMessage(
            role: .assistant,
            content: "Leader mode active. Pick one small deliverable and complete it before opening new threads.",
            projectID: projectID,
            into: &state
        )
        sessions[sessionID] = state
        return buildResponse(state: state, assistantMessage: assistantMessage, archiveEvent: nil)
    }

    public func postMessage(sessionID: String, content: String) -> ChatResponse {
        let pending = beginAssistantTurn(sessionID: sessionID, content: content)
        return completeAssistantTurn(
            sessionID: sessionID,
            content: pending.localReply,
            projectID: pending.selectedProjectID,
            archiveEvent: pending.archiveEvent
        )
    }

    public func beginAssistantTurn(sessionID: String, content: String) -> PendingAssistantTurn {
        var state = getOrCreateSession(sessionID: sessionID)
        let selectedProject = pickProject(for: content, state: &state)
        let archiveEvent = applyActiveCap(activatingProjectID: selectedProject.id, state: &state)
        state.selectedProjectID = selectedProject.id

        let userMessage = addMessage(role: .user, content: content, projectID: selectedProject.id, into: &state)
        touchProjectMomentum(projectID: selectedProject.id, content: content, state: &state)
        markCompletionSignal(content: content, state: &state)

        let scores = Scoring.computeScores(state: state)
        let breakdown = Scoring.computeBreakdown(state: state, scores: scores)
        let reply = Coach.response(to: content, state: state, scores: scores, breakdown: breakdown)

        sessions[sessionID] = state

        return PendingAssistantTurn(
            userMessage: userMessage,
            messages: state.messages,
            scores: scores,
            scoreBreakdown: breakdown,
            selectedProjectID: state.selectedProjectID,
            activeProjects: activeProjects(from: state),
            archivedProjects: archivedProjects(from: state),
            archiveEvent: archiveEvent,
            localReply: reply
        )
    }

    public func completeAssistantTurn(
        sessionID: String,
        content: String,
        projectID: String? = nil,
        archiveEvent: ArchiveEvent? = nil
    ) -> ChatResponse {
        var state = getOrCreateSession(sessionID: sessionID)
        let resolvedProjectID = projectID
            ?? state.selectedProjectID
            ?? state.projects.first?.id
            ?? makeID(prefix: "proj")
        let assistantMessage = addMessage(role: .assistant, content: content, projectID: resolvedProjectID, into: &state)
        sessions[sessionID] = state
        return buildResponse(state: state, assistantMessage: assistantMessage, archiveEvent: archiveEvent)
    }

    public func finish(sessionID: String) -> ChatResponse {
        var state = getOrCreateSession(sessionID: sessionID)
        let scores = Scoring.computeScores(state: state)
        let projectID = state.selectedProjectID ?? state.projects.first?.id ?? makeID(prefix: "proj")
        let assistantMessage = addMessage(
            role: .assistant,
            content: "Session reflection: Focus \(scores.focus)%, Momentum \(scores.momentum)%, Progress \(scores.progress)%. Close one more small step to lock in momentum.",
            projectID: projectID,
            into: &state
        )

        sessions[sessionID] = state
        return buildResponse(state: state, assistantMessage: assistantMessage, archiveEvent: nil)
    }

    public func switchProject(sessionID: String, projectID: String) -> (active: [Project], archived: [Project], archiveEvent: ArchiveEvent?) {
        var state = getOrCreateSession(sessionID: sessionID)
        guard state.projects.contains(where: { $0.id == projectID }) else {
            return (
                active: activeProjects(from: state),
                archived: archivedProjects(from: state),
                archiveEvent: nil
            )
        }

        let event = applyActiveCap(activatingProjectID: projectID, state: &state)
        state.selectedProjectID = projectID
        state.updatedAt = Date()
        sessions[sessionID] = state

        return (
            active: activeProjects(from: state),
            archived: archivedProjects(from: state),
            archiveEvent: event
        )
    }

    @discardableResult
    public func renameProject(sessionID: String, projectID: String, name: String) -> Project? {
        var state = getOrCreateSession(sessionID: sessionID)
        guard let index = state.projects.firstIndex(where: { $0.id == projectID }) else {
            return nil
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        state.projects[index].name = trimmed
        state.updatedAt = Date()
        sessions[sessionID] = state
        return state.projects[index]
    }

    @discardableResult
    public func reassignMessage(sessionID: String, messageID: String, projectID: String) -> Bool {
        var state = getOrCreateSession(sessionID: sessionID)
        guard state.projects.contains(where: { $0.id == projectID }),
              let messageIndex = state.messages.firstIndex(where: { $0.id == messageID }) else {
            return false
        }

        state.messages[messageIndex].projectID = projectID
        if let targetIndex = state.projects.firstIndex(where: { $0.id == projectID }) {
            state.projects[targetIndex].lastTouchedAt = Date()
        }
        state.updatedAt = Date()
        sessions[sessionID] = state
        return true
    }

    public func archivedPage(sessionID: String, cursor: Int?, limit: Int = archivedPageSize) -> (projects: [Project], nextCursor: Int?) {
        let state = getOrCreateSession(sessionID: sessionID)
        let archived = archivedProjects(from: state)
        let start = max(0, cursor ?? 0)
        let end = min(archived.count, start + limit)
        let slice = Array(archived[start..<end])
        let next = end < archived.count ? end : nil
        return (projects: slice, nextCursor: next)
    }

    public func sessionState(sessionID: String) -> SessionState {
        getOrCreateSession(sessionID: sessionID)
    }

    public func reset() {
        sessions.removeAll()
    }

    private func getOrCreateSession(sessionID: String) -> SessionState {
        if let existing = sessions[sessionID] {
            return existing
        }

        let now = Date()
        let project = Project(
            id: makeID(prefix: "proj"),
            name: "General",
            colorHex: Self.projectColors[0],
            status: .active,
            momentum: 5,
            hardness: 5,
            timeRequired: 5,
            feasibility: 6,
            centroid: [:],
            messageCount: 0,
            lastTouchedAt: now
        )

        let state = SessionState(
            sessionID: sessionID,
            startedAt: now,
            updatedAt: now,
            selectedProjectID: project.id,
            projects: [project],
            messages: [],
            planUnits: 6,
            completedUnits: 0
        )

        sessions[sessionID] = state
        return state
    }

    private func pickProject(for content: String, state: inout SessionState) -> Project {
        let vector = NLP.vectorize(content)
        if vector.isEmpty {
            if let selectedProjectID = state.selectedProjectID,
               let selected = state.projects.first(where: { $0.id == selectedProjectID }) {
                return selected
            }

            return state.projects.first ?? Project(
                id: makeID(prefix: "proj"),
                name: "General",
                colorHex: Self.projectColors[0],
                status: .active,
                momentum: 5,
                hardness: 5,
                timeRequired: 5,
                feasibility: 6,
                centroid: [:],
                messageCount: 0,
                lastTouchedAt: Date()
            )
        }

        let active = state.projects.filter { $0.status == .active }

        var bestProject: Project?
        var bestScore: Double = -1

        for project in active {
            let score = NLP.cosineSimilarity(project.centroid, vector)
            if score > bestScore {
                bestScore = score
                bestProject = project
            }
        }

        if bestProject == nil || bestScore < Self.newProjectThreshold {
            let color = Self.projectColors[state.projects.count % Self.projectColors.count]
            var created = Project(
                id: makeID(prefix: "proj"),
                name: "Project \(state.projects.count + 1)",
                colorHex: color,
                status: .active,
                momentum: 5,
                hardness: 5,
                timeRequired: 5,
                feasibility: 6,
                centroid: vector,
                messageCount: 1,
                lastTouchedAt: Date()
            )
            created.status = .active
            state.projects.append(created)
            return created
        }

        guard let projectID = bestProject?.id,
              let index = state.projects.firstIndex(where: { $0.id == projectID }) else {
            return state.projects[0]
        }

        state.projects[index].centroid = NLP.blendCentroid(
            centroid: state.projects[index].centroid,
            vector: vector,
            messageCount: state.projects[index].messageCount
        )
        state.projects[index].messageCount += 1
        state.projects[index].lastTouchedAt = Date()
        return state.projects[index]
    }

    private func applyActiveCap(activatingProjectID: String, state: inout SessionState) -> ArchiveEvent? {
        guard let targetIndex = state.projects.firstIndex(where: { $0.id == activatingProjectID }) else {
            return nil
        }

        state.projects[targetIndex].status = .active
        state.projects[targetIndex].lastTouchedAt = Date()

        var active = state.projects.filter { $0.status == .active }
        guard active.count > Self.activeProjectCap else {
            return nil
        }

        var archivedProjectID: String?
        while active.count > Self.activeProjectCap {
            let candidates = active.filter { $0.id != activatingProjectID }
            guard let archiveTarget = candidates.sorted(
                by: {
                    if $0.momentum == $1.momentum {
                        return $0.lastTouchedAt < $1.lastTouchedAt
                    }
                    return $0.momentum < $1.momentum
                }
            ).first,
                  let archiveIndex = state.projects.firstIndex(where: { $0.id == archiveTarget.id }) else {
                return nil
            }

            state.projects[archiveIndex].status = .archived
            if state.selectedProjectID == archiveTarget.id {
                state.selectedProjectID = activatingProjectID
            }
            archivedProjectID = archiveTarget.id
            active = state.projects.filter { $0.status == .active }
        }

        guard let archivedProjectID else { return nil }
        return ArchiveEvent(
            archivedProjectID: archivedProjectID,
            activatedProjectID: activatingProjectID
        )
    }

    private func addMessage(
        role: MessageRole,
        content: String,
        projectID: String,
        into state: inout SessionState
    ) -> ChatMessage {
        let message = ChatMessage(
            id: makeID(prefix: "msg"),
            role: role,
            content: content,
            createdAt: Date(),
            projectID: projectID
        )
        state.messages.append(message)
        state.updatedAt = Date()
        return message
    }

    private func markCompletionSignal(content: String, state: inout SessionState) {
        if content.range(of: "(?i)\\b(done|finished|shipped|completed|sent|closed)\\b", options: .regularExpression) != nil {
            state.completedUnits += 1
        }

        if content.range(of: "(?i)\\b(plan|todo|next|goal|scope)\\b", options: .regularExpression) != nil {
            state.planUnits = max(state.planUnits, state.completedUnits + 1)
        }
    }

    private func touchProjectMomentum(projectID: String, content: String, state: inout SessionState) {
        guard let index = state.projects.firstIndex(where: { $0.id == projectID }) else {
            return
        }

        let completionSignal = content.range(of: "(?i)\\b(done|finished|shipped|completed|sent|closed)\\b", options: .regularExpression) != nil
        let stuckSignal = content.range(of: "(?i)\\b(stuck|blocked|overwhelmed|switching|distracted)\\b", options: .regularExpression) != nil

        if completionSignal {
            state.projects[index].momentum = min(10, state.projects[index].momentum + 1.2)
        } else if stuckSignal {
            state.projects[index].momentum = max(1, state.projects[index].momentum - 0.8)
        } else {
            state.projects[index].momentum = min(10, state.projects[index].momentum + 0.2)
        }

        state.projects[index].hardness = min(10, max(1, state.projects[index].hardness + (stuckSignal ? 0.3 : -0.1)))
        state.projects[index].timeRequired = min(10, max(1, state.projects[index].timeRequired + (completionSignal ? -0.2 : 0.1)))
        state.projects[index].feasibility = min(10, max(1, state.projects[index].feasibility + (completionSignal ? 0.2 : -0.05)))
    }

    private func buildResponse(state: SessionState, assistantMessage: ChatMessage, archiveEvent: ArchiveEvent?) -> ChatResponse {
        let scores = Scoring.computeScores(state: state)
        let breakdown = Scoring.computeBreakdown(state: state, scores: scores)

        return ChatResponse(
            assistantMessage: assistantMessage,
            messages: state.messages,
            scores: scores,
            scoreBreakdown: breakdown,
            selectedProjectID: state.selectedProjectID,
            activeProjects: activeProjects(from: state),
            archivedProjects: archivedProjects(from: state),
            archiveEvent: archiveEvent
        )
    }

    private func activeProjects(from state: SessionState) -> [Project] {
        state.projects
            .filter { $0.status == .active }
            .sorted { $0.momentum > $1.momentum }
            .prefix(Self.activeProjectCap)
            .map { $0 }
    }

    private func archivedProjects(from state: SessionState) -> [Project] {
        state.projects
            .filter { $0.status == .archived }
            .sorted { $0.lastTouchedAt > $1.lastTouchedAt }
    }

    private func makeID(prefix: String) -> String {
        "\(prefix)_\(UUID().uuidString.prefix(8))"
    }
}
