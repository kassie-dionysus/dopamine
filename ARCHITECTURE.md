# ARCHITECTURE.md

## Purpose

This document defines the target architecture for Dopamine as a ChatGPT-native execution coach.

ChatGPT already provides projects. Dopamine adds longitudinal coaching so users stop drifting and finish outcomes.

## Product Constraints

- Maximum active projects: `3`.
- Each conversation belongs to exactly one project.
- A project can have many conversations.
- New project creation over cap requires user-selected demotion to archive.
- Assistant must always be aware of Focus, Momentum, Progress, and the active-cap rule.
- Users can manually override:
  - project names,
  - project ordering,
  - conversation-to-project assignments,
  - global and per-project custom instructions.

## High-Level Architecture

- `DopamineUI` (SwiftUI): onboarding, chat shell, project controls, metric reveal surfaces.
- `DopamineCore` (domain engine): state model, classification, scoring, ranking, coaching policy.
- `OpenAIGateway` (integration boundary): OpenAI API calls and model routing.
- `ImportPipeline` (integration boundary): ChatGPT share-link import and transcript ingestion.
- `Storage` (local + optional remote): projects, conversations, messages, settings, instructions, score history.

## Frontend Expected Behavior

## 1) Onboarding

First-launch flow:

1. Welcome screen with two paths:
   - `Import from ChatGPT share links`
   - `Start fresh`
2. API key setup:
   - ask for OpenAI API key before any network-backed assistant operations,
   - allow skip for local/non-API mode if supported,
   - show settings path to add/update key later.
3. Project initialization:
   - user can provide top goals/projects immediately, or
   - start chatting and allow Dopamine to infer top projects over time.

## 2) Main Chat Screen (ChatGPT-like)

- Keep the default screen chat-first.
- Show compact top indicators only:
  - global Focus indicator,
  - three active project chips with Momentum/Progress signals.
- Tap reveals:
  - metric details sheet,
  - project switcher (active + archived),
  - scoring rationale and "how to improve" actions.
- Keep archive muted and secondary.

## 3) Conversation and Project Actions

- User can enter Project A, B, or C and continue existing conversations.
- User can start a new conversation at any time.
- Each new conversation must be assigned to exactly one project.
- If off-topic drift is detected, show decision fork:
  - keep current project,
  - move conversation to another active project,
  - create new project (requires choosing one active project to archive).

## 4) Manual Overrides

- Rename project.
- Reorder active projects.
- Reassign conversation to another project.
- Edit global custom instructions.
- Edit per-project custom instructions.

## Backend Expected Behavior

## 1) API Key Management

- Capture key during onboarding or settings.
- Store in secure platform secret storage (for Apple platforms, Keychain).
- Never write key to logs, analytics payloads, or plain-text files.
- Gate OpenAI API requests when key is missing/invalid and show recovery UX.

## 2) Share Link Import Pipeline

- Input: one or more ChatGPT share URLs.
- Pipeline:
  1. fetch shared conversation content,
  2. parse transcript turns + timestamps if available,
  3. map messages to imported conversations,
  4. infer project candidates and assignments,
  5. populate project/conversation/message store,
  6. compute initial Focus/Momentum/Progress.
- Import must be idempotent where possible (avoid duplicate ingestion).

## 3) Project Assignment and Drift Detection

- Assignment service maps each conversation to one project.
- Drift detector flags when message content diverges from the current project.
- Drift confidence threshold triggers fork UX in chat.
- User decision always overrides model assignment.

## 4) Scoring Engine

- `Focus` (global): penalize breadth and rapid context switching.
- `Momentum` (project): estimate pace toward completion based on recent completions and projected effort.
- `Progress` (project): weighted completion adjusted by difficulty and available resources.
- `onTrackProbability` (internal, project): combines momentum trend, blocker load, and completion confidence.
- Keep score history for trend-based coaching.

## 5) Ranking and Active-Cap Policy

- Default active ordering uses `onTrackProbability`.
- If creating a new project at cap:
  - prompt user to choose demotion target,
  - archive selected project,
  - activate new project.
- Preserve user overrides until user resets ordering.

## 6) Prompt Composition and Assistant Policy

For every assistant turn, build context from:

- global custom instructions,
- project-level custom instructions,
- current project and conversation metadata,
- Focus/Momentum/Progress values and trend,
- active-project cap and archive state.

Response policy:

1. If Focus low, ask priority clarification question.
2. If Momentum low, suggest smallest viable next action.
3. If Progress stalled, suggest scope cut or resource change.
4. End substantial responses with one explicit next action and done-state.
5. Keep encouragement realistic, not generic.

## Data Model (Conceptual)

- `Project`
  - `id`, `name`, `status(active|archived)`, `userOrder`, `onTrackProbability`
  - `difficulty`, `resourceProfile`, `momentum`, `progress`
  - `customInstructions`
- `Conversation`
  - `id`, `projectID`, `title`, `createdAt`, `updatedAt`, `source(imported|native)`
- `Message`
  - `id`, `conversationID`, `role`, `content`, `createdAt`
- `UserSettings`
  - `globalInstructions`
  - `openAIKeyRef` (secure store reference)
- `ScoreSnapshot`
  - `timestamp`, `focus`, `projectScores[]`

## User Flows

## Flow A: First Launch With Import

1. Launch app.
2. Enter OpenAI key or skip.
3. Paste ChatGPT share links.
4. Import and parse history.
5. System infers projects and assigns conversations.
6. User reviews top 3 active projects.
7. User can rename/reorder/reassign before chatting.

## Flow B: First Launch Fresh

1. Launch app.
2. Enter OpenAI key or skip.
3. Choose:
   - define projects now, or
   - start chatting.
4. If chatting first, system gradually infers top 3 projects and asks for confirmation.

## Flow C: New Conversation While At Cap

1. User starts new conversation.
2. Classifier checks fit with existing active projects.
3. If no fit and user wants new project:
   - ask which active project to archive,
   - activate new project,
   - attach conversation to the new project.

## Flow D: Off-Topic Drift Mid-Conversation

1. Drift detector confidence crosses threshold.
2. Assistant asks routing question in chat.
3. User picks stay/move/new.
4. System updates conversation assignment and scores.

## Flow E: Custom Instructions

1. User edits global instructions in settings.
2. User edits project instructions in project detail.
3. Prompt composer merges instructions every turn.

## Top Risks / Issues To Solve (Priority Order)

1. Share-link ingestion reliability.
   - Risk: parsing variance and brittle extraction from shared pages.
   - Need: robust parser strategy and fallback UX for partial import.
2. Privacy and security for imported transcripts and API key.
   - Risk: accidental logging or insecure persistence.
   - Need: strict secret handling, redaction, and local encryption strategy.
3. Project assignment accuracy.
   - Risk: wrong project links make users distrust the system.
   - Need: confidence thresholds + always-available manual correction.
4. Drift detection false positives.
   - Risk: too many interruptions in natural conversation.
   - Need: calibrated thresholds and low-friction dismiss controls.
5. Score explainability.
   - Risk: Focus/Momentum/Progress feel arbitrary.
   - Need: transparent "why score changed" and "how to improve" guidance.
6. On-track probability calibration.
   - Risk: incorrect ranking of top 3 projects.
   - Need: empirical tuning and user override persistence.
7. Prompt contract complexity.
   - Risk: global + project instructions + coaching policy conflict.
   - Need: deterministic prompt layering and guardrails.
8. Over-coaching vs under-coaching balance.
   - Risk: assistant becomes noisy or passive.
   - Need: intervention policy with rate limits and trigger windows.
9. Archive/demotion UX friction.
   - Risk: users feel punished by 3-project cap.
   - Need: reversible archive flow and clear rationale messaging.
10. Longitudinal performance and cost.
   - Risk: heavy historical analysis slows UX and increases token spend.
   - Need: incremental summaries, caching, and bounded context windows.

## Near-Term Validation Focus

- Confirm onboarding completion rates for key + import path.
- Measure manual correction frequency (rename/reassign/reorder).
- Track whether coaching interventions increase completion of next actions.
- Validate whether users maintain stable top 3 over time.
