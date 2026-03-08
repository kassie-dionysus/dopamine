import Foundation

/// Generates leader-style coaching responses and in-chat score explainability.
public enum Coach {
    private static func isScoreQuestion(_ text: String) -> Bool {
        text.range(of: "\\b(score|focus|momentum|progress|why|improve|better|increase|low)\\b", options: .regularExpression) != nil
    }

    public static func response(
        to content: String,
        state: SessionState,
        scores: Scores,
        breakdown: ScoreBreakdown
    ) -> String {
        let primary = state.projects
            .filter { $0.status == .active }
            .sorted { $0.momentum > $1.momentum }
            .first

        if isScoreQuestion(content.lowercased()) {
            return [
                "Focus \(scores.focus)%, Momentum \(scores.momentum)%, Progress \(scores.progress)%.",
                "Focus is driven by depth vs switching. \(breakdown.focus.improve)",
                "Momentum is about compounding recent wins. \(breakdown.momentum.improve)",
                "Progress reflects completion adjusted for hardness, time, and feasibility. \(breakdown.progress.improve)"
            ].joined(separator: " ")
        }

        let projectName = primary?.name ?? "the current project"
        let effort = scores.momentum >= 70 ? "easy" : (scores.momentum >= 45 ? "medium" : "easy")
        let feasibility = scores.progress >= 70 ? "high" : (scores.progress >= 45 ? "medium" : "low")

        return [
            "Leader call: stay on \(projectName) for one focused sprint.",
            "Next step (\(effort)): define and complete one concrete deliverable in 10 minutes.",
            "Feasibility is \(feasibility); momentum improves fastest if you finish before opening another thread."
        ].joined(separator: " ")
    }
}
