# AGENTS.md

Repository instructions for coding agents.

## Current Stack

This project is Swift-only.
Do not reintroduce JavaScript/TypeScript/Node runtime unless explicitly requested.
Do not add web-route or Next.js-style architecture back into this repository.

## Product Positioning

ChatGPT already has a Projects feature.
Dopamine is the "keep you on track" coaching layer on top of long-running chats.
The product should detect drift, loss of momentum, and confusion, then coach users back to outcomes.

## Product Invariants

- Dopamine optimizes depth over breadth.
- Keep active project cap at `3`.
- Each conversation must be linked to exactly one project.
- A project may contain many conversations.
- When a new project would exceed cap, user must choose a project to demote/archive.
- Maintain internal per-project `onTrackProbability` for ranking defaults.
- Use `onTrackProbability` to decide default top 3 ordering on load.
- Allow user override of top 3 ordering.
- Keep three user-facing metrics: Focus, Momentum, Progress.
- Focus is global (across project conversations), based on message breadth and switching.
- Momentum is per project, based on projected completion velocity.
- Progress is per project, weighted by difficulty and available resources.
- Metric explanations should be conversationally available through chat behavior.
- Assistant behavior should be PM-like: clarify priority, propose realistic next steps, unblock issues, and encourage completion with realism.

## Onboarding Invariants

- First-run must support OpenAI key entry before API-backed chat/import actions.
- Store OpenAI key securely (platform secret storage), never in plaintext project files.
- First-run must offer ChatGPT share-link import.
- Import path should fetch shared conversations and ingest history into Dopamine state.
- User can skip import and start fresh.
- User can either define initial projects/goals or start chatting and let Dopamine infer projects.

## Assistant Context Contract

- Assistant must be aware of:
  - active-project cap of 3,
  - project/conversation assignment rules,
  - Focus/Momentum/Progress definitions,
  - coaching objective for users who drift into half-finished ideas.
- Support custom instructions at two levels:
  - global Dopamine instructions,
  - per-project instructions.
- Prompt assembly must merge global + project-level instructions deterministically.

## UI Invariants

- Keep interaction model close to the ChatGPT iOS app (chat-first, minimal chrome).
- Show only 3 active projects in primary UI; archived projects remain muted and secondary.
- Keep top indicator behavior: compact/unlabeled by default, tap reveals details.
- Keep project status indicators lightweight in primary view, with deeper explanations in sheets.
- Preserve manual correction controls:
  - rename project,
  - manually assign/reassign conversation to project,
  - reorder active projects.
- Support creating a new conversation from any point and routing it to a single project.
- When off-topic is detected, surface the decision fork in-chat (stay, move, or new project + demotion).
- Avoid dashboard-heavy, label-dense default screens.

## Engineering Standards

- Prefer small, focused Swift files and typed models.
- Add tests for behavior changes in `Tests/DopamineCoreTests`.
- Keep public API surface minimal and explicit.
- Avoid adding dependencies unless necessary.

## Validation

Run before finalizing:

```bash
xcrun swift test
xcrun swift run DopamineCLI
```
