# ARCHITECTURE.md

## Purpose

This document separates the architecture that exists in the repository **today** from the larger Dopamine product architecture that is still **planned**.

That distinction matters because the current codebase is still a prototype, even though it now includes a checked-in iOS app project alongside the Swift package.

## Current Implemented Architecture

The repository currently has four package products:

1. `DopamineCore`
   - In-memory domain logic.
   - Owns project models, message models, scoring, routing heuristics, archive policy, coaching text generation, and the basic OpenAI Responses API client.
   - Has no persistence or production-grade service boundaries yet.

2. `DopamineUI`
   - SwiftUI shell around `DopamineCore`.
   - Uses Swift Observation for UI state.
   - Provides an adaptive local interface for macOS and iPhone-class layouts.
   - Stores a developer API key in Keychain and can route assistant replies through OpenAI for simulator/device validation.

3. `DopamineApp`
   - Shared SwiftUI app entry point stored in `App/iOS`.
   - Built by SwiftPM for local macOS validation and by `Dopamine.xcodeproj` for iOS simulator/device runs.
   - Still not a production release target with finalized signing, assets, capabilities, or metadata.

4. `DopamineCLI`
   - Terminal smoke harness for validating the prototype engine.

## Current Data Flow

1. A session starts in `DopamineEngine`.
2. A user message is routed to an existing or new project using lightweight token similarity.
3. The engine updates project heuristics and score inputs.
4. `Scoring` computes `Focus`, `Momentum`, and `Progress`.
5. `Coach` produces a local response string.
6. `DopamineUI` renders the updated session state.
7. When OpenAI mode is enabled, the UI sends the prepared transcript to the Responses API and appends the returned assistant text back into the session.

## Current Known Gaps

These product pieces are part of the target vision but are **not** implemented in the current repository:

- persistent project, conversation, and message storage
- ChatGPT share-link import
- real conversation entities and conversation-to-project storage
- user-controlled archive choice when creating a fourth active project
- `onTrackProbability` ranking
- deterministic prompt assembly for global plus per-project instructions
- first-run API key onboarding
- production-quality service boundaries for OpenAI and import workflows
- release-grade signing, assets, metadata, and App Store distribution setup

## Product Constraints That Must Survive Growth

- Maximum active projects: `3`
- Each conversation belongs to exactly one project
- A project can have many conversations
- New project creation over cap must require explicit user demotion or archive choice in the production UX
- Assistant behavior must remain aware of Focus, Momentum, Progress, and the active-cap rule
- Users must be able to manually rename, reorder, and reassign

## Planned Production Architecture

When the prototype grows into a real app, use a feature-oriented Apple-platform architecture with explicit boundaries.

### App Layer

- checked-in iOS app target
- scene setup
- navigation
- dependency assembly
- signing and release configuration

### Feature Layer

- onboarding
- main chat shell
- project management surfaces
- import flow
- settings and instructions

Each feature should own its own SwiftUI views and presentation logic.

### Shared Domain And Services

- project, conversation, message, and score models
- ranking and coaching policies
- prompt composition rules
- integration protocols
- configuration
- logging and diagnostics

### Integration Layer

- OpenAI gateway
- ChatGPT share-link import pipeline
- persistence adapters
- secure secret storage
- optional analytics and monitoring

## Apple-Platform Guidance

- Keep SwiftUI-facing state on the main actor.
- Prefer Swift Observation over legacy `ObservableObject` on the current deployment targets.
- Keep domain logic reusable and isolated from SwiftUI.
- Use explicit dependency injection instead of global singletons.
- Mark docs clearly when they describe future state instead of implemented code.

## Delivery Implication

The package and checked-in Xcode project are ready for local validation.
The repository is not yet ready for App Store submission without the missing production services and release configuration listed above.
