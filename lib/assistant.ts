import type { ScoreBreakdown, Scores, SessionState } from "@/lib/types";

function formatPercent(value: number): string {
  return `${Math.round(value)}%`;
}

function isScoreQuestion(content: string): boolean {
  return /\b(score|focus|momentum|progress|why|improve|better|increase|low)\b/i.test(content);
}

export function createAssistantReply(
  content: string,
  scores: Scores,
  breakdown: ScoreBreakdown,
  state: SessionState
): string {
  const activeProjects = state.projects.filter((project) => project.status === "active");
  const primary = activeProjects.sort((a, b) => b.momentum - a.momentum)[0];

  if (isScoreQuestion(content)) {
    return [
      `Focus ${formatPercent(scores.focus)}, Momentum ${formatPercent(scores.momentum)}, Progress ${formatPercent(scores.progress)}.`,
      `Focus is driven by depth vs switching. ${breakdown.focus.improve}`,
      `Momentum is about compounding recent wins. ${breakdown.momentum.improve}`,
      `Progress reflects completion adjusted for hardness, time, and feasibility. ${breakdown.progress.improve}`
    ].join(" ");
  }

  const projectName = primary?.name ?? "the current project";
  const effort = scores.momentum >= 70 ? "easy" : scores.momentum >= 45 ? "medium" : "easy";
  const feasibility = scores.progress >= 70 ? "high" : scores.progress >= 45 ? "medium" : "low";

  return [
    `Leader call: stay on ${projectName} for one focused sprint.`,
    `Next step (${effort}): define and complete one concrete deliverable in 10 minutes.`,
    `Feasibility is ${feasibility}; momentum improves fastest if you finish before opening another thread.`
  ].join(" ");
}
