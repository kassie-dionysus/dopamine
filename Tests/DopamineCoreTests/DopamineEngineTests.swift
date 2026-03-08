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
}
