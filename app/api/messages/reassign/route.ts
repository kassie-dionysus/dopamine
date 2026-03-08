import { NextResponse } from "next/server";
import { reassignMessage } from "@/lib/store";

export async function POST(request: Request) {
  const body = (await request.json()) as { sessionId?: string; messageId?: string; projectId?: string };
  if (!body.sessionId || !body.messageId || !body.projectId) {
    return NextResponse.json({ error: "sessionId, messageId and projectId are required" }, { status: 400 });
  }

  const success = reassignMessage(body.sessionId, body.messageId, body.projectId);
  if (!success) {
    return NextResponse.json({ error: "Message or project not found" }, { status: 404 });
  }

  return NextResponse.json({ success: true });
}
