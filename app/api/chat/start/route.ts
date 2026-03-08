import { NextResponse } from "next/server";
import { getSessionMessages, startSession } from "@/lib/store";

export async function POST(request: Request) {
  const body = (await request.json()) as { sessionId?: string };
  if (!body.sessionId) {
    return NextResponse.json({ error: "sessionId is required" }, { status: 400 });
  }

  const payload = startSession(body.sessionId);
  return NextResponse.json({ ...payload, messages: getSessionMessages(body.sessionId) });
}
