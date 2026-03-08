import Foundation

/// Computes Focus, Momentum, and Progress using Dopamine's depth-first heuristics.
public enum Scoring {
    private static func clamp(_ value: Double) -> Int {
        Int(max(0, min(100, value.rounded())))
    }

    private static func switchingPenalty(projects: [Project], messages: [ChatMessage]) -> Double {
        guard messages.count >= 4 else { return 0 }

        let recent = Array(messages.suffix(10))
        var switches = 0
        for idx in 1..<recent.count where recent[idx].projectID != recent[idx - 1].projectID {
            switches += 1
        }

        let activeCount = projects.filter { $0.status == .active }.count
        return min(35, Double(switches * 7) + Double(max(0, activeCount - 1) * 5))
    }

    private static func completionRate(state: SessionState) -> Double {
        guard state.planUnits > 0 else { return 0 }
        return min(1, Double(state.completedUnits) / Double(state.planUnits))
    }

    private static func projectHealth(_ project: Project) -> Double {
        let hardnessFactor = 1 - project.hardness / 10
        let timeFactor = 1 - project.timeRequired / 10
        let feasibilityFactor = project.feasibility / 10
        return (hardnessFactor * 0.35 + timeFactor * 0.25 + feasibilityFactor * 0.40) * 100
    }

    public static func computeScores(state: SessionState) -> Scores {
        let activeProjects = state.projects.filter { $0.status == .active }

        let focus = clamp(100 - switchingPenalty(projects: activeProjects, messages: state.messages))

        let momentumAverage = activeProjects.isEmpty
            ? 0
            : activeProjects.reduce(0) { $0 + $1.momentum } / Double(activeProjects.count)
        let momentum = clamp(momentumAverage * 10)

        let progressFromCompletion = completionRate(state: state) * 55
        let progressFromProjectHealth = activeProjects.isEmpty
            ? 0
            : (activeProjects.reduce(0) { $0 + projectHealth($1) } / Double(activeProjects.count)) * 0.45

        let progress = clamp(progressFromCompletion + progressFromProjectHealth)

        return Scores(focus: focus, momentum: momentum, progress: progress)
    }

    public static func computeBreakdown(state: SessionState, scores: Scores) -> ScoreBreakdown {
        let active = state.projects.filter { $0.status == .active }
        let slow = active.sorted { $0.momentum < $1.momentum }.first
        let hard = active.sorted { $0.hardness > $1.hardness }.first

        return ScoreBreakdown(
            focus: ScoreBreakdownItem(
                score: scores.focus,
                drivers: [
                    "Sustained work inside a smaller set of active projects",
                    "Lower context switching in recent messages"
                ],
                detractors: [
                    "Frequent jumps across projects",
                    "Adding new threads before closing active work"
                ],
                improve: "Stay on one project for the next 2-3 turns and close one micro-step before switching."
            ),
            momentum: ScoreBreakdownItem(
                score: scores.momentum,
                drivers: [
                    "Recent completions compound confidence",
                    "Continuing work in the same project keeps pace"
                ],
                detractors: [
                    slow.map { "\($0.name) has low recent movement" } ?? "Sparse completions across active goals",
                    "Long gaps between completed actions"
                ],
                improve: "Pick one active project and complete an easy step in under 10 minutes right now."
            ),
            progress: ScoreBreakdownItem(
                score: scores.progress,
                drivers: [
                    "Completed planned work increases delivery confidence",
                    "Higher feasibility projects move faster"
                ],
                detractors: [
                    hard.map { "\($0.name) is high difficulty and needs decomposition" } ?? "Plan is not fully decomposed",
                    "Large tasks are not yet broken into easy next actions"
                ],
                improve: "Convert the hardest open item into one concrete next action with a clear done-state and time-box it."
            )
        )
    }
}
