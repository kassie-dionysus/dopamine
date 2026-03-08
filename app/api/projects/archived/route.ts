import { NextResponse } from "next/server";
import { getArchivedPage } from "@/lib/store";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const sessionId = url.searchParams.get("sessionId");
  const cursor = url.searchParams.get("cursor") ?? undefined;

  if (!sessionId) {
    return NextResponse.json({ error: "sessionId is required" }, { status: 400 });
  }

  const payload = getArchivedPage(sessionId, cursor);
  return NextResponse.json(payload);
}
