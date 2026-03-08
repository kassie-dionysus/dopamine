# Dopamine

Dopamine is a ChatGPT-native coaching layer for people who chat a lot, start many ideas, and struggle to finish.

ChatGPT already has a Projects feature. Dopamine does not replace it. Dopamine tracks conversation behavior over time and actively coaches users back to outcomes.

## Who It Is For

Users who:

- give up too early,
- jump between ideas,
- lose track of priorities,
- do not know how far along they are,
- need encouragement that is realistic about effort.

## Core Product Contract

- Active projects are capped at `3`.
- Each conversation belongs to exactly one project.
- A project can have many conversations.
- Additional projects must be archived/demoted explicitly by user choice when over cap.
- Users can rename projects, reorder top projects, and manually reassign conversations at any time.
- Users can set custom instructions:
  - global instructions for all Dopamine behavior,
  - project-level instructions for one project.

## Metrics

- `Focus` (global): how concentrated the user is across recent chats, based on topic breadth and context switching.
- `Momentum` (per project): projected speed and likelihood of reaching completion.
- `Progress` (per project): weighted completion adjusted for project difficulty and available resources.
- `On-Track Probability` (internal per project): ranking signal used to choose default top 3 shown on load.
- User ordering can override default ranking.

## First-Launch Flow

1. User opens app.
2. User chooses whether to connect OpenAI API key.
3. User chooses import path:
   - import prior context from ChatGPT share links, or
   - start fresh.
4. If importing:
   - app fetches link content,
   - parses conversation history,
   - imports messages and derives project assignments.
5. User chooses startup mode:
   - provide top goals/projects now, or
   - start chatting and let Dopamine infer top 3 over time.

## Daily Flow

1. User enters Project A, B, or C, or starts a new conversation.
2. New conversation is categorized to one of the active projects.
3. If content is off-topic, app asks whether to:
   - keep in selected project,
   - move to another active project,
   - create a new project (then demote one active project to archive).
4. Assistant responds with coaching that is aware of Focus/Momentum/Progress and the 3-project constraint.

## How ChatGPT Becomes a Proactive Coach

Dopamine prompts the assistant with project state, score state, and constraints so it behaves like a product manager from ideation to productization.

Mechanism:

1. Infer project and drift risk from each turn.
2. Recompute Focus/Momentum/Progress continuously.
3. Select one coaching intervention when needed:
   - priority question when focus drops,
   - scope reduction when progress stalls,
   - next-step nudge when momentum dips,
   - encouragement grounded in realistic effort and timeline.
4. End each substantial response with one concrete next action and a done-state.
5. If user is stuck, assistant guides through blockers instead of letting the thread drift.

## UX Direction (iPhone)

Stay very close to the OpenAI ChatGPT iOS interaction model:

- chat-first primary surface,
- minimal indicator row for focus/project status,
- detail surfaces on tap (metrics sheet, project switcher, archive sheet),
- no dashboard-heavy default home.

See:

- [iOS Chat Coach Layout](/Users/kdio/codex/dopamine/docs/ios-chat-coach-layout.md)
- [Architecture](/Users/kdio/codex/dopamine/ARCHITECTURE.md)

## Architecture Summary

- `DopamineCore`: state, classification, scoring, coaching policy, archive/ranking policy.
- `DopamineUI`: onboarding, chat-first shell, project controls, metric reveal surfaces.
- `DopamineApp`: SwiftUI app entry point.
- `DopamineCLI`: local harness for behavior validation.

## Current Status

- `Package.swift`
- `ARCHITECTURE.md`
- `Sources/DopamineApp/`
- `Sources/DopamineCore/`
- `Sources/DopamineUI/`
- `Sources/DopamineCLI/`
- `Tests/DopamineCoreTests/`
- `docs/`

## Build and Validation

### Prerequisites

- Swift 6 toolchain.
- macOS + Xcode for full package testing (SwiftUI target availability).

### Standard validation commands

```bash
xcrun swift test
xcrun swift run DopamineCLI
```

### Run app shell (macOS)

```bash
xcrun swift run DopamineApp
```

### Run in Xcode

1. Open `/Users/kdio/codex/dopamine/Package.swift` in Xcode.
2. Select the `DopamineApp` scheme.
3. Build and run.

## License

No license has been added yet.
