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

## iOS Shift Backlog

1. Define iOS product behavior from the web app (what stays the same, what changes for mobile UX).
2. Choose iOS stack and architecture (recommended: React Native + Expo).
3. Scaffold the iOS app project and baseline CI for simulator/device builds.
4. Implement the core iOS shell: metric bar area, project selector, and chat navigation.
5. Build project management UI: top 3 active projects, muted archived list, paged/infinite archived loading.
6. Build chat UI: message list, project color stripe, composer, and leader-style assistant responses.
7. Integrate API client layer for all existing endpoints with typed request/response handling.
8. Add manual correction flows on iOS: rename project and reassign message-to-project.
9. Implement metric interaction: unlabeled bars by default, tap to reveal name + percentage only.
10. Run iOS QA and release prep: functional checks, performance/accessibility pass, and TestFlight setup.

## iOS Shift Execution Plan

### Phase 1: Foundation (Tasks 1-3)

1. Lock parity requirements between web and iOS (focus bars, active cap = 3, archive behavior, in-chat score explanations).
2. Finalize iOS technical choices (React Native + Expo + TypeScript, backend API reuse, state strategy).
3. Scaffold iOS app and CI baseline (project bootstrapping, env config, simulator build verification).

### Phase 2: Core Experience (Tasks 4-6)

4. Build navigation shell with top metric strip and primary chat/project flows.
5. Implement project management UX for active and archived projects.
6. Implement chat UI with project stripe styling and leader-style response rendering.

### Phase 3: Integration + Controls (Tasks 7-9)

7. Integrate typed API client with robust loading/error handling.
8. Implement project rename and message reassignment correction flows.
9. Implement unlabeled metric bar interactions with tap-to-reveal details only.

### Phase 4: Release Readiness (Task 10)

10. Complete QA, performance/accessibility checks, and TestFlight packaging.

## License

No license has been added yet.
