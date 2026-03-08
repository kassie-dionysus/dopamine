import { NextResponse } from "next/server";
import { getSessionMessages, postUserMessage } from "@/lib/store";

export async function POST(request: Request) {
  const body = (await request.json()) as { sessionId?: string; message?: string };
  if (!body.sessionId || !body.message) {
    return NextResponse.json({ error: "sessionId and message are required" }, { status: 400 });
  }

  const payload = postUserMessage(body.sessionId, body.message);
  return NextResponse.json({ ...payload, messages: getSessionMessages(body.sessionId) });
}
