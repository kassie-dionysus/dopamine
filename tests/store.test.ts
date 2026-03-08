import { describe, expect, it, beforeEach } from "vitest";
import { postUserMessage, resetStore, startSession } from "@/lib/store";

describe("store", () => {
  beforeEach(() => {
    resetStore();
  });

  it("archives lowest-momentum project when active projects exceed cap", () => {
    startSession("s1");

    postUserMessage("s1", "build landing page copy and publish draft");
    postUserMessage("s1", "finalize budget spreadsheet for q2");
    const response = postUserMessage("s1", "plan a customer interview script and recruiting list");

    expect(response.activeProjects).toHaveLength(3);
    expect(response.archivedProjects.length).toBeGreaterThanOrEqual(1);
  });

  it("returns all three metric scores", () => {
    startSession("s1");
    const response = postUserMessage("s1", "I finished the first task and sent it");

    expect(response.scores.focus).toBeGreaterThanOrEqual(0);
    expect(response.scores.momentum).toBeGreaterThanOrEqual(0);
    expect(response.scores.progress).toBeGreaterThanOrEqual(0);
  });
});
