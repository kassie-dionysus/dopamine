import { NextResponse } from "next/server";
import { switchProject } from "@/lib/store";

export async function POST(request: Request) {
  const body = (await request.json()) as { sessionId?: string; projectId?: string };
  if (!body.sessionId || !body.projectId) {
    return NextResponse.json({ error: "sessionId and projectId are required" }, { status: 400 });
  }

  const payload = switchProject(body.sessionId, body.projectId);
  return NextResponse.json(payload);
}
