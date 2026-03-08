# Dopamine

Dopamine is a depth-first productivity coach built in Swift. It helps users stay focused by limiting active work to three projects, preserving momentum through completion-first coaching, and surfacing progress in a way users can discuss naturally in chat.

## Product Goal

Dopamine is designed around one behavior change loop:

1. **Constrain scope** to at most three active projects.
2. **Encourage visible completion** through small, concrete actions.
3. **Continuously explain** Focus, Momentum, and Progress in conversational language.

The system is intentionally opinionated: depth over breadth.

## Core Product Invariants

- Maximum active projects is **3**.
- If the cap is exceeded, archive the **lowest-momentum** active project.
- Always maintain three metrics: **Focus**, **Momentum**, **Progress**.
- Metric explanations must be available through chat behavior.

## User Stories

### Primary user stories

- As a user, I can chat naturally about my work and Dopamine groups messages into projects so I do not need to manually organize everything.
- As a user, I can only keep up to three active projects, so I am nudged to finish before I expand.
- As a user, I can ask why a score changed and receive a practical explanation with an immediate next step.
- As a user, I can manually correct project organization by renaming projects and reassigning messages.

### UX-specific stories

- As a user, I can quickly see active projects highlighted and archived projects muted in the rail.
- As a user, I see unlabeled metric bars by default and can tap to reveal each metric name + percentage.
- As a user, each chat message preserves project-color striping so project context remains visible.

## Repository Architecture

### `DopamineCore`

Domain and behavior engine:

- Session state, message/project models, and typed responses.
- Lightweight NLP routing (token vectors + cosine similarity).
- Active cap / archive policy enforcement.
- Focus, Momentum, Progress scoring + score breakdown generation.
- Leader-style coaching response generation.

### `DopamineUI`

SwiftUI presentation layer:

- Project rail (active highlighted, archived muted).
- Top metric strip with tap-to-reveal behavior.
- Conversation pane with project-color stripe messages.
- Manual correction controls (rename + reassign).

### `DopamineCLI`

CLI harness for deterministic smoke validation of core behavior.

## Current Status

- ✅ Swift rewrite complete.
- ✅ Core model + scoring + routing behaviors implemented.
- ✅ SwiftUI module available for integration into app targets.
- ⚠️ Full iOS app target and production persistence/network integration are still planned.

## Build and Validation

### Prerequisites

- Swift 6 toolchain.
- macOS + Xcode for full package testing (SwiftUI target availability).

### Standard validation commands

```bash
xcrun swift test
xcrun swift run DopamineCLI
```

### Environment note

In non-Apple environments (e.g., Linux CI), `DopamineUI` compilation may fail due to missing `SwiftUI`. In that case, prefer validating `DopamineCLI` behavior and run full tests on macOS CI.

## Implementation Plan

A principal-engineer-level implementation plan is maintained in:

- [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)

It contains phased execution, sequencing, acceptance criteria, risks, and validation strategy.

## Repository Layout

- `Package.swift`
- `Sources/DopamineCore/`
- `Sources/DopamineUI/`
- `Sources/DopamineCLI/`
- `Tests/DopamineCoreTests/`
- `docs/IMPLEMENTATION_PLAN.md`

## License

No license has been added yet.
