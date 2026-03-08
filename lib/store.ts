import { ACTIVE_PROJECT_CAP, ARCHIVED_PAGE_SIZE, NEW_PROJECT_THRESHOLD, PROJECT_COLORS } from "@/lib/constants";
import { createAssistantReply } from "@/lib/assistant";
import { blendCentroid, cosineSimilarity, vectorize } from "@/lib/nlp";
import { computeScoreBreakdown, computeScores } from "@/lib/scoring";
import type {
  ArchiveEvent,
  ChatMessage,
  ChatResponse,
  Project,
  ScoreBreakdown,
  Scores,
  SessionState
} from "@/lib/types";

const sessions = new Map<string, SessionState>();

function createId(prefix: string): string {
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}`;
}

function now(): number {
  return Date.now();
}

function defaultProject(name: string, color: string): Project {
  return {
    id: createId("proj"),
    name,
    color,
    status: "active",
    momentum: 5,
    hardness: 5,
    timeRequired: 5,
    feasibility: 6,
    centroid: {},
    messageCount: 0,
    lastTouchedAt: now()
  };
}

function createSession(sessionId: string): SessionState {
  const started = now();
  const project = defaultProject("General", PROJECT_COLORS[0] ?? "#1982c4");
  const session: SessionState = {
    sessionId,
    startedAt: started,
    updatedAt: started,
    selectedProjectId: project.id,
    projects: [project],
    messages: [],
    planUnits: 6,
    completedUnits: 0
  };
  sessions.set(sessionId, session);
  return session;
}

export function getOrCreateSession(sessionId: string): SessionState {
  return sessions.get(sessionId) ?? createSession(sessionId);
}

function getActiveProjects(state: SessionState): Project[] {
  return state.projects.filter((project) => project.status === "active");
}

function getArchivedProjects(state: SessionState): Project[] {
  return state.projects
    .filter((project) => project.status === "archived")
    .sort((a, b) => b.lastTouchedAt - a.lastTouchedAt);
}

function pickProjectForMessage(state: SessionState, content: string): Project {
  const vector = vectorize(content);
  const active = getActiveProjects(state);

  let bestProject: Project | null = null;
  let bestScore = -1;

  for (const project of active) {
    const score = cosineSimilarity(project.centroid, vector);
    if (score > bestScore) {
      bestScore = score;
      bestProject = project;
    }
  }

  if (!bestProject || bestScore < NEW_PROJECT_THRESHOLD) {
    const color = PROJECT_COLORS[state.projects.length % PROJECT_COLORS.length] ?? "#1982c4";
    const created = defaultProject(`Project ${state.projects.length + 1}`, color);
    created.centroid = vector;
    created.messageCount = 1;
    created.lastTouchedAt = now();
    state.projects.push(created);
    applyActiveCap(state, created.id);
    return created;
  }

  bestProject.centroid = blendCentroid(bestProject.centroid, vector, bestProject.messageCount);
  bestProject.messageCount += 1;
  bestProject.lastTouchedAt = now();
  return bestProject;
}

function applyActiveCap(state: SessionState, activatingProjectId: string): ArchiveEvent | null {
  const target = state.projects.find((project) => project.id === activatingProjectId);
  if (!target) {
    return null;
  }
  target.status = "active";
  target.lastTouchedAt = now();

  const active = getActiveProjects(state);
  if (active.length <= ACTIVE_PROJECT_CAP) {
    return null;
  }

  const candidates = active.filter((project) => project.id !== activatingProjectId);
  const toArchive = candidates.sort((a, b) => a.momentum - b.momentum || a.lastTouchedAt - b.lastTouchedAt)[0];
  if (!toArchive) {
    return null;
  }

  toArchive.status = "archived";
  if (state.selectedProjectId === toArchive.id) {
    state.selectedProjectId = activatingProjectId;
  }

  return {
    archivedProjectId: toArchive.id,
    activatedProjectId: activatingProjectId
  };
}

function addMessage(state: SessionState, role: ChatMessage["role"], content: string, projectId: string): ChatMessage {
  const message: ChatMessage = {
    id: createId("msg"),
    role,
    content,
    createdAt: now(),
    projectId
  };
  state.messages.push(message);
  state.updatedAt = now();
  return message;
}

function markCompletionSignal(state: SessionState, content: string): void {
  if (/\b(done|finished|shipped|completed|sent|closed)\b/i.test(content)) {
    state.completedUnits += 1;
  }
  if (/\bplan|todo|next|goal|scope\b/i.test(content)) {
    state.planUnits = Math.max(state.planUnits, state.completedUnits + 1);
  }
}

function touchProjectMomentum(project: Project, content: string): void {
  const completionSignal = /\b(done|finished|shipped|completed|sent|closed)\b/i.test(content);
  const stuckSignal = /\b(stuck|blocked|overwhelmed|switching|distracted)\b/i.test(content);

  if (completionSignal) {
    project.momentum = Math.min(10, project.momentum + 1.2);
  } else if (stuckSignal) {
    project.momentum = Math.max(1, project.momentum - 0.8);
  } else {
    project.momentum = Math.min(10, project.momentum + 0.2);
  }

  project.hardness = Math.max(1, Math.min(10, project.hardness + (stuckSignal ? 0.3 : -0.1)));
  project.timeRequired = Math.max(1, Math.min(10, project.timeRequired + (completionSignal ? -0.2 : 0.1)));
  project.feasibility = Math.max(1, Math.min(10, project.feasibility + (completionSignal ? 0.2 : -0.05)));
}

function buildResponse(
  state: SessionState,
  assistantMessage: ChatMessage,
  scores: Scores,
  breakdown: ScoreBreakdown,
  archiveEvent: ArchiveEvent | null
): ChatResponse {
  const activeProjects = getActiveProjects(state).sort((a, b) => b.momentum - a.momentum).slice(0, ACTIVE_PROJECT_CAP);
  const archivedProjects = getArchivedProjects(state);

  return {
    assistantMessage,
    scores,
    scoreBreakdown: breakdown,
    activeProjects,
    archivedProjects,
    archiveEvent
  };
}

export function startSession(sessionId: string): ChatResponse {
  const state = getOrCreateSession(sessionId);
  const scores = computeScores(state);
  const breakdown = computeScoreBreakdown(state, scores);
  const projectId = state.selectedProjectId ?? state.projects[0]?.id;
  const assistantMessage = addMessage(
    state,
    "assistant",
    "Leader mode active. Pick one small deliverable and complete it before opening new threads.",
    projectId ?? state.projects[0]!.id
  );
  return buildResponse(state, assistantMessage, scores, breakdown, null);
}

export function postUserMessage(sessionId: string, content: string): ChatResponse {
  const state = getOrCreateSession(sessionId);
  const selectedProject = pickProjectForMessage(state, content);
  const archiveEvent = applyActiveCap(state, selectedProject.id);
  state.selectedProjectId = selectedProject.id;

  addMessage(state, "user", content, selectedProject.id);
  touchProjectMomentum(selectedProject, content);
  markCompletionSignal(state, content);

  const scores = computeScores(state);
  const breakdown = computeScoreBreakdown(state, scores);
  const reply = createAssistantReply(content, scores, breakdown, state);
  const assistantMessage = addMessage(state, "assistant", reply, selectedProject.id);

  return buildResponse(state, assistantMessage, scores, breakdown, archiveEvent);
}

export function finishSession(sessionId: string): ChatResponse {
  const state = getOrCreateSession(sessionId);
  const scores = computeScores(state);
  const breakdown = computeScoreBreakdown(state, scores);
  const assistantMessage = addMessage(
    state,
    "assistant",
    `Session reflection: Focus ${scores.focus}%, Momentum ${scores.momentum}%, Progress ${scores.progress}%. Close one more small step to lock in momentum.`,
    state.selectedProjectId ?? state.projects[0]!.id
  );
  return buildResponse(state, assistantMessage, scores, breakdown, null);
}

export function switchProject(sessionId: string, projectId: string): {
  archiveEvent: ArchiveEvent | null;
  activeProjects: Project[];
  archivedProjects: Project[];
} {
  const state = getOrCreateSession(sessionId);
  const archiveEvent = applyActiveCap(state, projectId);
  state.selectedProjectId = projectId;
  const activeProjects = getActiveProjects(state).sort((a, b) => b.momentum - a.momentum).slice(0, ACTIVE_PROJECT_CAP);
  const archivedProjects = getArchivedProjects(state);
  return { archiveEvent, activeProjects, archivedProjects };
}

export function renameProject(sessionId: string, projectId: string, name: string): Project | null {
  const state = getOrCreateSession(sessionId);
  const project = state.projects.find((item) => item.id === projectId);
  if (!project) {
    return null;
  }
  project.name = name.trim() || project.name;
  return project;
}

export function reassignMessage(sessionId: string, messageId: string, projectId: string): boolean {
  const state = getOrCreateSession(sessionId);
  const message = state.messages.find((item) => item.id === messageId);
  const target = state.projects.find((project) => project.id === projectId);
  if (!message || !target) {
    return false;
  }
  message.projectId = projectId;
  target.lastTouchedAt = now();
  return true;
}

export function getSessionMessages(sessionId: string): ChatMessage[] {
  const state = getOrCreateSession(sessionId);
  return [...state.messages];
}

export function getArchivedPage(
  sessionId: string,
  cursor?: string
): { projects: Project[]; nextCursor: string | null } {
  const state = getOrCreateSession(sessionId);
  const archived = getArchivedProjects(state);
  const start = cursor ? Number.parseInt(cursor, 10) : 0;
  const page = archived.slice(start, start + ARCHIVED_PAGE_SIZE);
  const next = start + ARCHIVED_PAGE_SIZE < archived.length ? String(start + ARCHIVED_PAGE_SIZE) : null;
  return { projects: page, nextCursor: next };
}

export function getSessionProjects(sessionId: string): { activeProjects: Project[]; archivedProjects: Project[] } {
  const state = getOrCreateSession(sessionId);
  return {
    activeProjects: getActiveProjects(state).sort((a, b) => b.momentum - a.momentum).slice(0, ACTIVE_PROJECT_CAP),
    archivedProjects: getArchivedProjects(state)
  };
}

export function resetStore(): void {
  sessions.clear();
}
