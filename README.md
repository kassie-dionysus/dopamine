# Dopamine

Dopamine is a depth-first productivity chatbot that clusters conversations into projects, caps active work to three priorities, and coaches users toward small, high-leverage next steps.
It tracks Focus, Momentum, and Progress with compact top-level metric bars while keeping detailed score reasoning in-chat.

## Status

This is a local-demo v1 implementation built with Next.js App Router and an in-memory backend.

## Core Product Behaviors

- OpenAI-style chat layout with a dedicated project rail.
- Automatic project/topic inference from message content.
- Exactly 3 active projects are highlighted; overflow projects are archived.
- Archive policy: lowest-momentum active project is archived first.
- Archived projects are shown in muted gray with paged/infinite-scroll loading.
- Three unlabeled, color-coded horizontal metric bars at the top of the conversation area.
- Bar tap reveals only metric name + percentage.
- Score explanations and improvement coaching are intentionally handled via chat responses.
- Manual correction controls:
  - Rename project.
  - Reassign a message to a different project.

## Metrics

- `Focus`: depth over breadth; penalizes context switching.
- `Momentum`: compounding velocity from recent completions and continuity.
- `Progress`: completion quality adjusted by hardness, time required, and feasibility signals.

## Tech Stack

- Next.js `15.2.0`
- React `19`
- TypeScript
- Vitest + Testing Library
- In-memory session/project/message store

## Project Structure

- `app/page.tsx`: main UI shell and client state.
- `app/globals.css`: styling and responsive layout.
- `components/MetricBars.tsx`: top metric bar strip with tap-to-reveal.
- `lib/store.ts`: in-memory state, project cap/archive logic, and message handling.
- `lib/nlp.ts`: lightweight text vectorization and cosine similarity clustering.
- `lib/scoring.ts`: Focus/Momentum/Progress scoring logic.
- `lib/assistant.ts`: leader-style chat reply generation including score explainability.
- `app/api/**`: REST endpoints used by the client.
- `tests/**`: unit/component tests.

## API Endpoints

- `POST /api/chat/start`
  - Body: `{ sessionId }`
  - Returns initial assistant response, projects, scores, and messages.
- `POST /api/chat/message`
  - Body: `{ sessionId, message }`
  - Returns assistant response + updated scores/projects/messages.
- `POST /api/chat/finish`
  - Body: `{ sessionId }`
  - Returns reflection response + final metrics snapshot.
- `POST /api/projects/switch`
  - Body: `{ sessionId, projectId }`
  - Applies top-3 cap/archive policy as needed and switches active context.
- `POST /api/projects/rename`
  - Body: `{ sessionId, projectId, name }`
- `POST /api/messages/reassign`
  - Body: `{ sessionId, messageId, projectId }`
- `GET /api/projects/archived?sessionId=...&cursor=...`
  - Returns paged archived project data.

## Local Development

### Prerequisites

- Node.js 18+
- npm 9+

### Install

```bash
npm install
```

### Run

```bash
npm run dev
```

Then open [http://localhost:3000](http://localhost:3000).

### Test

```bash
npm test
```

### Production Build

```bash
npm run build
npm start
```

## Current Limitations

- In-memory state only (no database persistence).
- Anonymous sessions only (no authentication).
- Lightweight local vectorization for topic inference (not embeddings service-backed yet).
- Local demo quality by design.

## Suggested Next Steps

- Replace local vectorization with embedding-based clustering.
- Add persistent storage for sessions/projects/history.
- Add auth + per-user workspaces.
- Add audit trail for project reassignment/rename actions.
- Add richer momentum/progress calibration from explicit task events.

## License

No license has been added yet.
