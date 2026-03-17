# Dopamine

<<<<<<< ours
<<<<<<< ours
Dopamine is a chat-first coaching layer for people who start too many ideas, drift between threads, and need help finishing outcomes.

ChatGPT already has Projects. Dopamine is the layer on top that keeps users on track over time.

## What This Repository Is Today

This repository is a Swift package plus a checked-in iOS Xcode project.
=======
Dopamine is a depth-first productivity coach built in Swift. It helps users stay focused by limiting active work to three projects, preserving momentum through completion-first coaching, and surfacing progress in a way users can discuss naturally in chat.
=======
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
>>>>>>> theirs

## Product Goal

<<<<<<< ours
Dopamine is designed around one behavior change loop:

1. **Constrain scope** to at most three active projects.
2. **Encourage visible completion** through small, concrete actions.
3. **Continuously explain** Focus, Momentum, and Progress in conversational language.
=======
Domain and behavior engine:

- Session state, message/project models, and typed responses.
- Lightweight NLP routing (token vectors + cosine similarity).
- Active cap / archive policy enforcement.
- Focus, Momentum, Progress scoring + score breakdown generation.
- Leader-style coaching response generation.
>>>>>>> theirs

The system is intentionally opinionated: depth over breadth.

<<<<<<< ours
## Core Product Invariants

- Maximum active projects is **3**.
- If the cap is exceeded, archive the **lowest-momentum** active project.
- Always maintain three metrics: **Focus**, **Momentum**, **Progress**.
- Metric explanations must be available through chat behavior.

## User Stories
=======
SwiftUI presentation layer:

- Project rail (active highlighted, archived muted).
- Top metric strip with tap-to-reveal behavior.
- Conversation pane with project-color stripe messages.
- Manual correction controls (rename + reassign).
>>>>>>> theirs

### Primary user stories

<<<<<<< ours
- As a user, I can chat naturally about my work and Dopamine groups messages into projects so I do not need to manually organize everything.
- As a user, I can only keep up to three active projects, so I am nudged to finish before I expand.
- As a user, I can ask why a score changed and receive a practical explanation with an immediate next step.
- As a user, I can manually correct project organization by renaming projects and reassigning messages.

### UX-specific stories

- As a user, I can quickly see active projects highlighted and archived projects muted in the rail.
- As a user, I see unlabeled metric bars by default and can tap to reveal each metric name + percentage.
- As a user, each chat message preserves project-color striping so project context remains visible.

## Repository Architecture
>>>>>>> theirs
=======
CLI harness for deterministic smoke validation of core behavior.

## Current Status

- ✅ Swift rewrite complete.
- ✅ Core model + scoring + routing behaviors implemented.
- ✅ SwiftUI module available for integration into app targets.
- ⚠️ Full iOS app target and production persistence/network integration are still planned.

## Build and Validation
>>>>>>> theirs

It currently gives you:

<<<<<<< ours
- `DopamineCore`: in-memory project routing, scoring, and coaching heuristics
- `DopamineUI`: SwiftUI views and state for the shared app shell
- `DopamineApp`: a shared SwiftUI app entry point that the package can build on macOS
- `DopamineCLI`: a terminal harness for behavior validation
- `Dopamine.xcodeproj`: a real iOS app project that imports the local package
- a basic OpenAI Responses API path with Keychain-backed developer API key storage in the app shell

It does **not** yet give you:
=======
Domain and behavior engine:

- Session state, message/project models, and typed responses.
- Lightweight NLP routing (token vectors + cosine similarity).
- Active cap / archive policy enforcement.
- Focus, Momentum, Progress scoring + score breakdown generation.
- Leader-style coaching response generation.
>>>>>>> theirs

- persistence, share-link import, or production-grade OpenAI service architecture
- production release metadata, app icons, screenshots, and finalized signing/distribution setup

<<<<<<< ours
## Product Rules

- Active projects are capped at `3`.
- Each conversation must belong to exactly one project.
- A project may contain many conversations.
- Users must be able to rename projects, reassign conversations, and reorder active projects.
- User-facing metrics remain `Focus`, `Momentum`, and `Progress`.
- Internal ranking should eventually use `onTrackProbability`.

<<<<<<< ours
The current package implements a prototype subset of this contract. See [Architecture](/Users/kdio/codex/dopamine/ARCHITECTURE.md) for the exact boundary between implemented and planned behavior.
=======
SwiftUI presentation layer:

- Project rail (active highlighted, archived muted).
- Top metric strip with tap-to-reveal behavior.
- Conversation pane with project-color stripe messages.
- Manual correction controls (rename + reassign).
>>>>>>> theirs

## Repository Map

<<<<<<< ours
- `Package.swift`: package manifest
- `App/iOS/`: shared app entry point used by SwiftPM and Xcode
- `App/README.md`: notes on the checked-in app host source
- `Sources/DopamineCore/`: domain models, scoring, routing, and coaching logic
- `Sources/DopamineUI/`: SwiftUI shell and observation-based view model
- `Sources/DopamineCLI/`: CLI smoke harness
- `Dopamine.xcodeproj/`: checked-in iOS app project
- `project.yml`: XcodeGen spec used to regenerate the Xcode project
- `Tests/DopamineCoreTests/`: behavior tests for the core engine
- `docs/`: architecture, layout direction, implementation plan, and App Store setup
- `AGENTS.md`: machine-readable repo instructions

## Local Commands
=======
- Swift 6 toolchain.
- macOS + Xcode for full package testing (SwiftUI target availability).

### Standard validation commands
>>>>>>> theirs

```bash
xcrun swift test
xcrun swift run DopamineCLI
<<<<<<< ours
xcrun swift build
```

`xcrun swift run DopamineApp` still launches the shared package app shell on macOS, but it opens a GUI app and will stay running until you quit it.

If you edit `project.yml`, regenerate the Xcode project with:

```bash
xcodegen generate
```

## Open The iOS App In Xcode

1. Open Xcode.
2. Choose `File -> Open`.
3. Open `/Users/kdio/codex/dopamine/Dopamine.xcodeproj`.
4. If Xcode says the iOS platform is missing, install it from `Xcode -> Settings -> Components` or `Platforms`.
5. Select the `Dopamine` scheme.
6. Choose an iPhone simulator.
7. Press Run.

If the destination menu only shows an iOS runtime error, command-line tools may still be pointing at the wrong developer directory:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Run The Shared App Shell On macOS

1. Open Xcode.
2. Choose `File -> Open`.
3. Select [Package.swift](/Users/kdio/codex/dopamine/Package.swift).
4. Wait for Xcode to resolve the package and create schemes.
5. Choose the `DopamineApp` scheme.
6. Choose the `My Mac` destination.
7. Press Run.

## Test OpenAI Replies In Simulator

1. Open [Dopamine.xcodeproj](/Users/kdio/codex/dopamine/Dopamine.xcodeproj) in Xcode.
2. Run the `Dopamine` scheme on an iPhone simulator.
3. Tap `OpenAI`.
4. Paste your developer API key and press `Save Key`.
5. Turn on `Use OpenAI replies`.
6. Send a basic message like `hi`, then `bye`.

The app stores the key in Keychain on the current device or simulator and sends chat turns through OpenAI's Responses API. This is a prototype developer flow, not the final production architecture.

## Current Limits

The repository now includes a real iOS app host, but it is still not App Store-ready.

Before TestFlight or App Store submission, Dopamine still needs:

- production signing and bundle review
- app icons and release metadata
- persistence, production API-key/onboarding flow, and share-link import
- production onboarding/settings flows

See [App Store Setup](/Users/kdio/codex/dopamine/docs/APP_STORE_SETUP.md) for the remaining release path.
=======
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

In non-Apple environments (e.g., Linux CI), SwiftUI views are conditionally compiled out so core and CLI validations can still run. Run full UI behavior checks on macOS CI.

## Implementation Plan

A principal-engineer-level implementation plan is maintained in:

- [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)

It contains phased execution, sequencing, acceptance criteria, risks, and validation strategy.

## Repository Layout

=======
```

### Environment note

In non-Apple environments (e.g., Linux CI), SwiftUI views are conditionally compiled out so core and CLI validations can still run. Run full UI behavior checks on macOS CI.

## Implementation Plan

A principal-engineer-level implementation plan is maintained in:

- [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)

It contains phased execution, sequencing, acceptance criteria, risks, and validation strategy.

## Repository Layout

>>>>>>> theirs
- `Package.swift`
- `Sources/DopamineCore/`
- `Sources/DopamineUI/`
- `Sources/DopamineCLI/`
- `Tests/DopamineCoreTests/`
- `docs/IMPLEMENTATION_PLAN.md`
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs

## Documentation Index

- [Architecture](/Users/kdio/codex/dopamine/ARCHITECTURE.md)
- [Implementation Plan](/Users/kdio/codex/dopamine/docs/IMPLEMENTATION_PLAN.md)
- [iOS Chat Coach Layout](/Users/kdio/codex/dopamine/docs/ios-chat-coach-layout.md)
- [App Store Setup](/Users/kdio/codex/dopamine/docs/APP_STORE_SETUP.md)
