import type { Project, ScoreBreakdown, Scores, SessionState } from "@/lib/types";

function clamp(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function switchingPenalty(projects: Project[], messages: SessionState["messages"]): number {
  if (messages.length < 4) {
    return 0;
  }
  const recent = messages.slice(-10);
  let switches = 0;
  for (let i = 1; i < recent.length; i += 1) {
    if (recent[i]?.projectId !== recent[i - 1]?.projectId) {
      switches += 1;
    }
  }
  const activeCount = projects.filter((project) => project.status === "active").length;
  return Math.min(35, switches * 7 + Math.max(0, activeCount - 1) * 5);
}

function completionRate(state: SessionState): number {
  if (state.planUnits <= 0) {
    return 0;
  }
  return Math.min(1, state.completedUnits / state.planUnits);
}

function projectHealth(project: Project): number {
  const hardnessFactor = 1 - project.hardness / 10;
  const timeFactor = 1 - project.timeRequired / 10;
  const feasibilityFactor = project.feasibility / 10;
  return (hardnessFactor * 0.35 + timeFactor * 0.25 + feasibilityFactor * 0.4) * 100;
}

export function computeScores(state: SessionState): Scores {
  const activeProjects = state.projects.filter((project) => project.status === "active");
  const focus = clamp(100 - switchingPenalty(activeProjects, state.messages));
  const momentumAverage =
    activeProjects.length > 0
      ? activeProjects.reduce((sum, project) => sum + project.momentum, 0) / activeProjects.length
      : 0;
  const momentum = clamp(momentumAverage * 10);

  const progressFromCompletion = completionRate(state) * 55;
  const progressFromProjectHealth =
    activeProjects.length > 0
      ? (activeProjects.reduce((sum, project) => sum + projectHealth(project), 0) / activeProjects.length) * 0.45
      : 0;

  const progress = clamp(progressFromCompletion + progressFromProjectHealth);

  return { focus, momentum, progress };
}

export function computeScoreBreakdown(state: SessionState, scores: Scores): ScoreBreakdown {
  const active = state.projects.filter((project) => project.status === "active");
  const slowProject = [...active].sort((a, b) => a.momentum - b.momentum)[0];
  const hardProject = [...active].sort((a, b) => b.hardness - a.hardness)[0];

  return {
    focus: {
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
    },
    momentum: {
      score: scores.momentum,
      drivers: [
        "Recent completions compound confidence",
        "Continuing work in the same project keeps pace"
      ],
      detractors: [
        slowProject ? `${slowProject.name} has low recent movement` : "Sparse completions across active goals",
        "Long gaps between completed actions"
      ],
      improve: "Pick one active project and complete an easy step in under 10 minutes right now."
    },
    progress: {
      score: scores.progress,
      drivers: [
        "Completed planned work increases delivery confidence",
        "Higher feasibility projects move faster"
      ],
      detractors: [
        hardProject ? `${hardProject.name} is high difficulty and needs decomposition` : "Plan is not fully decomposed",
        "Large tasks are not yet broken into easy next actions"
      ],
      improve:
        "Convert the hardest open item into one concrete next action with a clear done-state and time-box it."
    }
  };
}
