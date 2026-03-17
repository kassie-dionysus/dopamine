# Dopamine Implementation Plan

This plan defines the correct execution order for shipping Dopamine from current Swift package state to a production-quality iOS experience.

## 1) Objective and Non-Negotiables

### Objective

Ship a reliable iOS productivity coach that drives **focus**, **momentum**, and **progress** through constrained active work and high-quality conversational guidance.

### Product non-negotiables

- Active project cap stays at **3**.
<<<<<<< ours
<<<<<<< ours
- Production overflow handling requires an **explicit user-selected demotion or archive choice**.
=======
- Overflow handling archives the **lowest-momentum active project**.
>>>>>>> theirs
=======
- Overflow handling archives the **lowest-momentum active project**.
>>>>>>> theirs
- Metrics remain exactly: **Focus**, **Momentum**, **Progress**.
- Metric explainability remains conversationally available in chat.

### UX non-negotiables

- Active highlighted / archived muted project rail semantics.
- Unlabeled metric bars by default; tap reveals metric name + percent.
- Project-color stripe on messages.
- Manual correction controls: rename project, reassign message.

## 2) Scope Baseline (Current)

### Completed

<<<<<<< ours
<<<<<<< ours
1. Swift package architecture with `DopamineCore`, `DopamineUI`, `DopamineApp`, and `DopamineCLI`.
2. In-memory core engine with project routing, cap/archive policy, and score generation.
3. SwiftUI module implementing a local adaptive shell for rail, metric strip, and conversation layout.
4. Checked-in iOS app project backed by shared `App/iOS` source and the local package.
5. Basic OpenAI Responses API request flow with developer-key storage in Keychain.
6. CLI smoke harness for deterministic behavioral checks.

### Not yet completed

1. Production-ready signing, assets, and release workflow hardening.
2. Persistence and network/service layer hardening.
3. User-selected archive flow when creating a fourth active project.
4. Interaction polish, accessibility, and release hardening.
=======
=======
>>>>>>> theirs
1. Swift package architecture with `DopamineCore`, `DopamineUI`, and `DopamineCLI`.
2. In-memory core engine with project routing, cap/archive policy, and score generation.
3. SwiftUI module implementing core rail + metric strip + conversation layout.
4. CLI smoke harness for deterministic behavioral checks.

### Not yet completed

1. Production iOS app target integration.
2. Persistence and network/service layer hardening.
3. Interaction polish, accessibility, and release hardening.
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs

## 3) Ordered Delivery Plan

## Phase A — App Shell Foundation

### Goals

<<<<<<< ours
<<<<<<< ours
- Harden the checked-in Xcode iOS app target consuming `DopamineCore` and `DopamineUI`.
=======
- Create production iOS app target consuming `DopamineCore` and `DopamineUI`.
>>>>>>> theirs
=======
- Create production iOS app target consuming `DopamineCore` and `DopamineUI`.
>>>>>>> theirs
- Establish runtime configuration and environment handling.

### Tasks

<<<<<<< ours
<<<<<<< ours
1. Maintain the shared app host target and dependency wiring to Swift package modules.
2. Establish app lifecycle and root navigation shell around `DopamineRootView`.
3. Define environment configuration points (API key handling, feature flags, debug options).
4. Replace remaining prototype-only package-run assumptions with real app target settings.
=======
1. Add iOS app host target with dependency wiring to Swift package modules.
2. Establish app lifecycle and root navigation shell around `DopamineRootView`.
3. Define environment configuration points (API key handling, feature flags, debug options).
>>>>>>> theirs
=======
1. Add iOS app host target with dependency wiring to Swift package modules.
2. Establish app lifecycle and root navigation shell around `DopamineRootView`.
3. Define environment configuration points (API key handling, feature flags, debug options).
>>>>>>> theirs

### Exit criteria

- App launches to a working Dopamine shell on iOS simulator/device.
- No product invariants are regressed in app-host integration.

## Phase B — Data & Service Integration

### Goals

- Replace in-memory-only assumptions where needed.
- Introduce typed service boundary for model interactions.

### Tasks

1. Define protocol-first service interfaces in core-adjacent layer.
2. Implement persistence strategy for sessions/projects/messages.
<<<<<<< ours
<<<<<<< ours
3. Harden the current OpenAI-backed request pipeline while preserving explainability contract.
4. Add failure-handling and offline-safe UX states.
5. Evolve the current Keychain-backed developer-key flow into the final onboarding experience.
=======
3. Implement request pipeline for OpenAI-backed coaching flows while preserving explainability contract.
4. Add failure-handling and offline-safe UX states.
>>>>>>> theirs
=======
3. Implement request pipeline for OpenAI-backed coaching flows while preserving explainability contract.
4. Add failure-handling and offline-safe UX states.
>>>>>>> theirs

### Exit criteria

- Session continuity survives app restarts.
- Service errors do not corrupt project cap/archive semantics.

## Phase C — Interaction Quality and Corrections

### Goals

- Raise UX to production quality without violating behavior contract.

### Tasks

1. Refine project rail interactions for large archived sets and fast switching.
2. Harden rename/reassign UX (validation, confirmation, undo where appropriate).
3. Improve chat ergonomics (scroll behavior, input affordances, message grouping).
4. Validate metric strip interaction parity (hidden by default, explicit reveal).
<<<<<<< ours
<<<<<<< ours
5. Replace prototype auto-archive with explicit user choice plus suggested default.
=======
>>>>>>> theirs
=======
>>>>>>> theirs

### Exit criteria

- Manual correction flows are robust, discoverable, and low-friction.
- UX remains faithful to all listed invariants.

## Phase D — Quality, Safety, and Release

### Goals

- Ensure reliability and operational readiness.

### Tasks

1. Expand automated tests in `Tests/DopamineCoreTests` for behavior invariants and edge cases.
2. Add integration/UI test coverage for critical user journeys.
3. Run accessibility, performance, and regression audits.
4. Prepare release checklist, rollout strategy, and monitoring hooks.

### Exit criteria

- Test suite demonstrates invariant protection.
- Accessibility and performance are within release thresholds.
- Build is ready for TestFlight rollout.

## 4) Validation Strategy

Run before finalizing changes:

```bash
xcrun swift test
xcrun swift run DopamineCLI
```

Additional recommended checks on macOS CI:

1. Simulator UI smoke test for rail/metric/chat interactions.
2. Regression suite for project cap and archive policy.
3. Conversation explainability checks for Focus/Momentum/Progress responses.

## 5) Risk Register and Mitigations

1. **Risk:** Project routing quality degrades with ambiguous language.
   - **Mitigation:** Add correction-aware feedback loops and benchmark routing with representative transcripts.
2. **Risk:** Metric trust erosion from opaque score changes.
   - **Mitigation:** Keep in-chat, plain-language explanations first-class and test for explanation quality.
3. **Risk:** Overly rigid cap behavior frustrates users.
   - **Mitigation:** Preserve manual correction tools and communicate archive rationale in UI/chat.
4. **Risk:** Platform-specific test gaps (SwiftUI unavailable in non-Apple CI).
   - **Mitigation:** Use macOS CI for full package validation and keep CLI/core checks available cross-platform.

## 6) Definition of Done

A milestone is considered complete only when:

- Product and UX invariants remain intact.
- New behavior changes include tests in `Tests/DopamineCoreTests` when applicable.
- Documentation is updated to reflect actual implementation status.
- Validation commands are run and results recorded.
