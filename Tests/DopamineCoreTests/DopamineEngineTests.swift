import Testing
@testable import DopamineCore

/// Core behavior checks for the Swift engine rewrite.
struct DopamineEngineTests {
    @Test("Engine returns all three metric scores")
    func returnsMetrics() {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s1")

        let response = engine.postMessage(sessionID: "s1", content: "I finished the first task and shipped it")

        #expect(response.scores.focus >= 0 && response.scores.focus <= 100)
        #expect(response.scores.momentum >= 0 && response.scores.momentum <= 100)
        #expect(response.scores.progress >= 0 && response.scores.progress <= 100)
    }

    @Test("Engine enforces top-three active project cap")
    func enforcesActiveProjectCap() {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s2")

        _ = engine.postMessage(sessionID: "s2", content: "landing page copy launch campaign")
        _ = engine.postMessage(sessionID: "s2", content: "financial forecast spreadsheet q2 model")
        _ = engine.postMessage(sessionID: "s2", content: "user interview script recruiting pipeline")

        let state = engine.sessionState(sessionID: "s2")
        let active = state.projects.filter { $0.status == .active }
        let archived = state.projects.filter { $0.status == .archived }

        #expect(active.count == DopamineEngine.activeProjectCap)
        #expect(!archived.isEmpty)
    }

    @Test("Score questions receive explainability guidance")
    func scoreExplainability() {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s3")
        let response = engine.postMessage(sessionID: "s3", content: "Why is my focus low and how do I improve momentum?")

        #expect(response.assistantMessage.content.contains("Focus"))
        #expect(response.assistantMessage.content.contains("Momentum"))
        #expect(response.assistantMessage.content.contains("Progress"))
    }

    @Test("Selecting an unknown project leaves selection unchanged")
    func switchUnknownProjectIsNoOp() {
        let engine = DopamineEngine()
        let start = engine.start(sessionID: "s4")
        let selectedBefore = start.activeProjects.first?.id

        _ = engine.switchProject(sessionID: "s4", projectID: "proj_missing")

        let state = engine.sessionState(sessionID: "s4")
        #expect(state.selectedProjectID == selectedBefore)
    }

    @Test("Empty rename is rejected")
    func renameRejectsEmptyName() throws {
        let engine = DopamineEngine()
        let start = engine.start(sessionID: "s5")
        let projectID = try #require(start.activeProjects.first?.id)

        let renamed = engine.renameProject(sessionID: "s5", projectID: projectID, name: "   ")

        #expect(renamed == nil)
        let state = engine.sessionState(sessionID: "s5")
        let project = state.projects.first(where: { $0.id == projectID })
        #expect(project?.name == "General")
    }

    @Test("Uppercase completion keywords increment completion units")
    func completionSignalsAreCaseInsensitive() {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s6")

        _ = engine.postMessage(sessionID: "s6", content: "DONE and SHIPPED")

        let state = engine.sessionState(sessionID: "s6")
        #expect(state.completedUnits == 1)
    }

    @Test("Punctuation-only messages stay on selected project")
    func punctuationMessageDoesNotCreateProject() throws {
        let engine = DopamineEngine()
        let start = engine.start(sessionID: "s7")
        let selected = try #require(start.activeProjects.first?.id)

        _ = engine.postMessage(sessionID: "s7", content: "!!!")

        let state = engine.sessionState(sessionID: "s7")
        #expect(state.selectedProjectID == selected)
        #expect(state.projects.filter { $0.status == .active }.count == 1)
    }
<<<<<<< ours
<<<<<<< ours

    @Test("Responses carry the routed selected project")
    func responsesExposeSelectedProject() throws {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s8")

        let response = engine.postMessage(sessionID: "s8", content: "landing page copy launch campaign")
        let selectedProjectID = try #require(response.selectedProjectID)

        #expect(selectedProjectID == response.assistantMessage.projectID)
        #expect(engine.sessionState(sessionID: "s8").selectedProjectID == selectedProjectID)
    }

    @Test("Prepared turns can be completed with an external assistant reply")
    func preparedTurnsSupportExternalReplies() throws {
        let engine = DopamineEngine()
        _ = engine.start(sessionID: "s9")

        let pending = engine.beginAssistantTurn(sessionID: "s9", content: "hi there")
        #expect(pending.userMessage.role == .user)
        #expect(pending.messages.last?.role == .user)

        let response = engine.completeAssistantTurn(
            sessionID: "s9",
            content: "Hello from OpenAI",
            projectID: pending.selectedProjectID,
            archiveEvent: pending.archiveEvent
        )

        #expect(response.assistantMessage.content == "Hello from OpenAI")
        #expect(response.messages.last?.role == .assistant)
        #expect(response.messages.last?.projectID == pending.selectedProjectID)
    }
=======
>>>>>>> theirs
=======
>>>>>>> theirs
}
