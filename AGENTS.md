# AGENTS.md

Repository instructions for coding agents.

## Repo Summary

Dopamine is a Swift-only coaching product built on top of long-running chat behavior.

Current repository form:

- Swift package
- checked-in iOS `.xcodeproj` generated from `project.yml`
- shared app shell source used by both SwiftPM and Xcode
- not yet a production-ready release configuration for App Store distribution

Products built by this repository:

- `DopamineCore`
- `DopamineUI`
- `DopamineApp`
- `DopamineCLI`

## Current Stack

This project is Swift-only.
Do not reintroduce JavaScript, TypeScript, Node, or Next.js unless explicitly requested.

## Directory Map

- `Package.swift`: package manifest
- `App/iOS`: shared app entry point for the package executable and iOS Xcode target
- `App/README.md`: notes about the checked-in app host source
- `Sources/DopamineCore`: domain models, scoring, routing, and coaching heuristics
- `Sources/DopamineUI`: SwiftUI shell and view state
- `Sources/DopamineCLI`: local CLI smoke harness
- `Dopamine.xcodeproj`: checked-in iOS app project
- `project.yml`: XcodeGen spec for regenerating the Xcode project
- `Tests/DopamineCoreTests`: behavior tests for the core engine
- `docs/IMPLEMENTATION_PLAN.md`: ordered delivery plan from prototype to production
- `docs/ios-chat-coach-layout.md`: target iPhone interaction model
- `docs/APP_STORE_SETUP.md`: path from package prototype to App Store-ready app
- `ARCHITECTURE.md`: current vs planned architecture
- `README.md`: human-friendly quick start and repo overview

## Implemented Today

- In-memory project routing and score calculation
- Active project cap enforcement in the prototype engine
- Local SwiftUI shell for visual validation
- Checked-in iOS app host that imports the package
- Keychain-backed developer API key storage in the app shell
- Basic OpenAI Responses API request flow for live assistant replies
- CLI behavior harness
- Core tests with Swift Testing

## Not Yet Implemented

- First-run OpenAI key onboarding flow
- ChatGPT share-link import pipeline
- Persistence across launches
- Real conversation/project store with production data modeling
- `onTrackProbability`-driven ranking
- Production-grade OpenAI service architecture and release hardening
- Production release metadata, assets, and finalized signing/distribution configuration

## Product Positioning

ChatGPT already has a Projects feature.
Dopamine is the "keep you on track" coaching layer on top of long-running chats.
The product should detect drift, loss of momentum, and confusion, then coach users back to outcomes.

## Product Invariants

- Dopamine optimizes depth over breadth.
- Keep active project cap at `3`.
- Each conversation must be linked to exactly one project.
- A project may contain many conversations.
- When a new project would exceed cap, the production UX must ask the user which project to demote or archive.
- Maintain internal per-project `onTrackProbability` for ranking defaults.
- Use `onTrackProbability` to decide default top 3 ordering on load.
- Allow user override of top 3 ordering.
- Keep three user-facing metrics: Focus, Momentum, Progress.
- Focus is global across project conversations and is based on breadth and switching.
- Momentum is per project and is based on projected completion velocity.
- Progress is per project and is weighted by difficulty and available resources.
- Metric explanations should be conversationally available through chat behavior.
- Assistant behavior should be PM-like: clarify priority, propose realistic next steps, unblock issues, and encourage completion with realism.

## Onboarding Invariants

- First-run must support OpenAI key entry before API-backed chat or import actions.
- Store the OpenAI key securely in platform secret storage, never in plaintext files.
- First-run must offer ChatGPT share-link import.
- Import should fetch shared conversations and ingest history into Dopamine state.
- User can skip import and start fresh.
- User can either define initial projects up front or start chatting and let Dopamine infer projects.

## Assistant Context Contract

The assistant must be aware of:

- the active-project cap of `3`
- project and conversation assignment rules
- Focus, Momentum, and Progress definitions
- the coaching objective for users who drift into half-finished ideas

Support custom instructions at two levels:

- global Dopamine instructions
- per-project instructions

Prompt assembly must merge global and project-level instructions deterministically.

## UI Invariants

- Keep interaction close to the ChatGPT iOS app: chat-first and minimal chrome.
- Show only `3` active projects in the primary surface.
- Keep the top indicator behavior compact and mostly unlabeled by default.
- Keep project status indicators lightweight in the primary view and deeper in sheets.
- Preserve manual correction controls:
  - rename project
  - manually assign or reassign a conversation
  - reorder active projects
- Support creating a new conversation from any point and routing it to exactly one project.
- When off-topic drift is detected, surface the decision fork in chat: stay, move, or new project plus demotion.
- Avoid dashboard-heavy default screens.

## Engineering Standards

- Prefer small, focused Swift files and typed models.
- Use modern Swift idioms available on the stated deployment targets.
- Keep public API surface minimal and explicit.
- Avoid adding dependencies unless necessary.
- Add tests for behavior changes in `Tests/DopamineCoreTests`.
- Keep documentation explicit about what is implemented today versus planned work.

## Validation

Run before finalizing:

```bash
xcrun swift test
xcrun swift run DopamineCLI
```
