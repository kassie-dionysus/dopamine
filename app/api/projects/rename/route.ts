import { NextResponse } from "next/server";
import { renameProject } from "@/lib/store";

export async function POST(request: Request) {
  const body = (await request.json()) as { sessionId?: string; projectId?: string; name?: string };
  if (!body.sessionId || !body.projectId || !body.name) {
    return NextResponse.json({ error: "sessionId, projectId and name are required" }, { status: 400 });
  }

  const project = renameProject(body.sessionId, body.projectId, body.name);
  if (!project) {
    return NextResponse.json({ error: "Project not found" }, { status: 404 });
  }

  return NextResponse.json({ project });
}
