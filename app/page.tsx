"use client";

import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { MetricBars } from "@/components/MetricBars";
import type { BarState, ChatMessage, Project, Scores } from "@/lib/types";

const SESSION_ID = "local-session";

interface ChatPayload {
  messages: ChatMessage[];
  activeProjects: Project[];
  archivedProjects: Project[];
  scores: Scores;
}

interface SwitchPayload {
  activeProjects: Project[];
  archivedProjects: Project[];
}

const BAR_COLORS = {
  focus: "#00b4d8",
  momentum: "#ff9f1c",
  progress: "#2a9d8f"
} as const;

async function postJson<T>(url: string, body: unknown): Promise<T> {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }

  return (await response.json()) as T;
}

async function fetchArchived(cursor: string | null): Promise<{ projects: Project[]; nextCursor: string | null }> {
  const params = new URLSearchParams({ sessionId: SESSION_ID });
  if (cursor) {
    params.set("cursor", cursor);
  }
  const response = await fetch(`/api/projects/archived?${params.toString()}`);
  if (!response.ok) {
    throw new Error("Failed to fetch archived projects");
  }
  return (await response.json()) as { projects: Project[]; nextCursor: string | null };
}

export default function HomePage() {
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [activeProjects, setActiveProjects] = useState<Project[]>([]);
  const [archivedProjects, setArchivedProjects] = useState<Project[]>([]);
  const [scores, setScores] = useState<Scores>({ focus: 55, momentum: 50, progress: 40 });
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(null);
  const [archivedCursor, setArchivedCursor] = useState<string | null>(null);
  const [loadingArchived, setLoadingArchived] = useState(false);

  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const run = async () => {
      const payload = await postJson<ChatPayload>("/api/chat/start", { sessionId: SESSION_ID });
      setMessages(payload.messages);
      setActiveProjects(payload.activeProjects);
      setArchivedProjects(payload.archivedProjects.slice(0, 12));
      setScores(payload.scores);
      setSelectedProjectId(payload.activeProjects[0]?.id ?? null);
      setArchivedCursor(payload.archivedProjects.length > 12 ? "12" : null);
    };

    run().catch((error: unknown) => {
      console.error(error);
    });
  }, []);

  const bars: BarState[] = useMemo(
    () => [
      { id: "focus", value: scores.focus, color: BAR_COLORS.focus, revealed: false },
      { id: "momentum", value: scores.momentum, color: BAR_COLORS.momentum, revealed: false },
      { id: "progress", value: scores.progress, color: BAR_COLORS.progress, revealed: false }
    ],
    [scores]
  );

  const visibleMessages = useMemo(() => {
    if (!selectedProjectId) {
      return messages;
    }
    return messages.filter((message) => message.projectId === selectedProjectId);
  }, [messages, selectedProjectId]);

  async function handleSend(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!input.trim()) {
      return;
    }
    const payload = await postJson<ChatPayload>("/api/chat/message", {
      sessionId: SESSION_ID,
      message: input
    });
    setInput("");
    setMessages(payload.messages);
    setActiveProjects(payload.activeProjects);
    setArchivedProjects(payload.archivedProjects.slice(0, Math.max(12, archivedProjects.length)));
    setScores(payload.scores);
    if (!selectedProjectId && payload.activeProjects[0]) {
      setSelectedProjectId(payload.activeProjects[0].id);
    }
  }

  async function handleSelectProject(projectId: string) {
    const payload = await postJson<SwitchPayload>("/api/projects/switch", {
      sessionId: SESSION_ID,
      projectId
    });
    setSelectedProjectId(projectId);
    setActiveProjects(payload.activeProjects);
    setArchivedProjects(payload.archivedProjects);
  }

  async function handleRenameProject(projectId: string) {
    const nextName = window.prompt("Rename project");
    if (!nextName?.trim()) {
      return;
    }
    await postJson("/api/projects/rename", {
      sessionId: SESSION_ID,
      projectId,
      name: nextName
    });
    setActiveProjects((previous) =>
      previous.map((project) => (project.id === projectId ? { ...project, name: nextName } : project))
    );
    setArchivedProjects((previous) =>
      previous.map((project) => (project.id === projectId ? { ...project, name: nextName } : project))
    );
  }

  async function handleReassignMessage(messageId: string, projectId: string) {
    await postJson("/api/messages/reassign", {
      sessionId: SESSION_ID,
      messageId,
      projectId
    });
    setMessages((previous) => previous.map((msg) => (msg.id === messageId ? { ...msg, projectId } : msg)));
  }

  async function handleArchivedScroll() {
    const node = scrollRef.current;
    if (!node || loadingArchived || !archivedCursor) {
      return;
    }
    const threshold = node.scrollHeight - node.clientHeight - 40;
    if (node.scrollTop < threshold) {
      return;
    }

    setLoadingArchived(true);
    try {
      const page = await fetchArchived(archivedCursor);
      setArchivedProjects((previous) => [...previous, ...page.projects]);
      setArchivedCursor(page.nextCursor);
    } finally {
      setLoadingArchived(false);
    }
  }

  const projectLookup = new Map([...activeProjects, ...archivedProjects].map((project) => [project.id, project]));

  return (
    <div className="app-shell">
      <aside className="project-pane">
        <h1 className="logo">dopamine</h1>
        <div className="project-group">
          <p className="group-label">Active</p>
          {activeProjects.map((project) => (
            <div
              key={project.id}
              className={`project-item active ${selectedProjectId === project.id ? "selected" : ""}`}
            >
              <button className="project-main" onClick={() => handleSelectProject(project.id)} type="button">
                <span className="project-dot" style={{ backgroundColor: project.color }} />
                <span className="project-name">{project.name}</span>
              </button>
              <button className="project-rename" type="button" onClick={() => handleRenameProject(project.id)}>
                rename
              </button>
            </div>
          ))}
        </div>
        <div className="project-group archived-wrap" ref={scrollRef} onScroll={handleArchivedScroll}>
          <p className="group-label">Archived</p>
          {archivedProjects.map((project) => (
            <button
              key={project.id}
              className="project-item archived"
              onClick={() => handleSelectProject(project.id)}
              type="button"
            >
              <span className="project-dot" style={{ backgroundColor: "#6d6f7a" }} />
              <span className="project-name">{project.name}</span>
            </button>
          ))}
        </div>
      </aside>
      <main className="conversation-pane">
        <MetricBars bars={bars} />
        <section className="chat-pane">
          <div className="messages">
            {visibleMessages.map((message) => (
              <article key={message.id} className={`message ${message.role}`}>
                <span
                  className="stripe"
                  style={{
                    backgroundColor:
                      message.projectId ? projectLookup.get(message.projectId)?.color ?? "#8a8f9e" : "#8a8f9e"
                  }}
                />
                <div className="message-content">
                  <p>{message.content}</p>
                  {message.role === "user" ? (
                    <label className="reassign">
                      Move:
                      <select
                        value={message.projectId}
                        onChange={(event) => handleReassignMessage(message.id, event.target.value)}
                      >
                        {[...activeProjects, ...archivedProjects].map((project) => (
                          <option key={project.id} value={project.id}>
                            {project.name}
                          </option>
                        ))}
                      </select>
                    </label>
                  ) : null}
                </div>
              </article>
            ))}
          </div>
          <form className="composer" onSubmit={handleSend}>
            <textarea
              placeholder="Tell dopamine what you are doing next..."
              value={input}
              onChange={(event) => setInput(event.target.value)}
              rows={2}
            />
            <button type="submit">Send</button>
          </form>
        </section>
      </main>
    </div>
  );
}
