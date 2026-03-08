export type MetricId = "focus" | "momentum" | "progress";

export type MessageRole = "user" | "assistant";

export type ProjectStatus = "active" | "archived";

export interface Scores {
  focus: number;
  momentum: number;
  progress: number;
}

export interface ScoreBreakdownItem {
  score: number;
  drivers: string[];
  detractors: string[];
  improve: string;
}

export interface ScoreBreakdown {
  focus: ScoreBreakdownItem;
  momentum: ScoreBreakdownItem;
  progress: ScoreBreakdownItem;
}

export interface Project {
  id: string;
  name: string;
  color: string;
  status: ProjectStatus;
  momentum: number;
  hardness: number;
  timeRequired: number;
  feasibility: number;
  centroid: Record<string, number>;
  messageCount: number;
  lastTouchedAt: number;
}

export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  createdAt: number;
  projectId: string;
}

export interface SessionState {
  sessionId: string;
  startedAt: number;
  updatedAt: number;
  selectedProjectId: string | null;
  projects: Project[];
  messages: ChatMessage[];
  planUnits: number;
  completedUnits: number;
}

export interface ArchiveEvent {
  archivedProjectId: string;
  activatedProjectId: string;
}

export interface ChatResponse {
  assistantMessage: ChatMessage;
  scores: Scores;
  scoreBreakdown: ScoreBreakdown;
  activeProjects: Project[];
  archivedProjects: Project[];
  archiveEvent: ArchiveEvent | null;
}

export interface BarState {
  id: MetricId;
  value: number;
  color: string;
  revealed: boolean;
}
