# Dopamine (Swift Rewrite)

Dopamine is a depth-first focus coach that clusters conversations into projects, caps active work to 3 goals, and guides users toward small, high-leverage steps.
This repository is now fully rewritten in Swift.

## What Changed

- Removed the previous Next.js/TypeScript implementation.
- Replaced the project with a Swift package architecture.
- Preserved core product behavior:
  - Automatic project/topic clustering.
  - Active-project cap with archive fallback.
  - Focus, Momentum, Progress scoring.
  - Leader-style coaching responses with score explainability in chat.

## Architecture

### `DopamineCore`

Swift domain engine and business logic:

- Session state and project/message models.
- Topic inference via token vectors + cosine similarity.
- Top-3 active cap and lowest-momentum archive policy.
- Focus, Momentum, Progress scoring and breakdowns.
- Leader-style response generation.
- In-process engine APIs (no HTTP server required in this repo).

### `DopamineUI`

SwiftUI views and view model:

- Left project rail (active highlighted, archived muted).
- Top 25% metric strip with 3 unlabeled color bars.
- Tap-to-reveal metric name + percentage.
- Chat pane with project-stripe messages.
- Manual correction flows:
  - Rename project.
  - Reassign message to project.

Note: `DopamineUI` is a SwiftUI module. Packaging into an iOS app target is tracked in the backlog below.

### `DopamineCLI`

CLI harness for local behavior testing and demo runs.

## Repo Layout

- `Package.swift`
- `Sources/DopamineCore/`
- `Sources/DopamineUI/`
- `Sources/DopamineCLI/`
- `Tests/DopamineCoreTests/`

## Build and Test

### Prerequisites

- Xcode 16+ (or Swift 6 toolchain)
- macOS with Swift toolchain installed

### Run tests

```bash
xcrun swift test
```

### Run CLI demo

```bash
xcrun swift run DopamineCLI
```

## iOS Shift Backlog

1. [x] Define iOS product behavior from the existing model (parity vs mobile adaptations).
2. [x] Choose iOS stack and architecture (Swift package + SwiftUI modules).
3. [x] Scaffold baseline project and CI-testable Swift package structure.
4. [ ] Implement full app shell integration in an iOS app target.
5. [ ] Implement production-grade project rail UX (active + archived infinite list).
6. [ ] Implement production chat UX polish and interaction refinements.
7. [ ] Integrate persistence/network service layer where required.
8. [ ] Harden rename and reassignment correction flows in app-level UX.
9. [ ] Finalize metric interaction contract (unlabeled by default, tap reveal only).
10. [ ] Complete QA and TestFlight release prep.

## iOS Shift Execution Plan

### Phase 1: Foundation (Tasks 1-3)

1. Lock parity requirements.
2. Finalize iOS architecture decisions.
3. Scaffold iOS app + CI foundation.

### Phase 2: Core Experience (Tasks 4-6)

4. Build shell/navigation and metric region.
5. Build active/archived project UX.
6. Build full chat experience.

### Phase 3: Integration + Controls (Tasks 7-9)

7. Add typed service integration.
8. Add project/message correction controls.
9. Finish metric interaction behavior.

### Phase 4: Release Readiness (Task 10)

10. Execute QA, accessibility, performance, and TestFlight packaging.

## License

No license has been added yet.
