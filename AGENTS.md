# AGENTS.md

Repository instructions for coding agents.

## Current Stack

This project is Swift-only.
Do not reintroduce JavaScript/TypeScript/Node runtime unless explicitly requested.
Do not add web-route or Next.js-style architecture back into this repository.

## Product Invariants

- Dopamine optimizes depth over breadth.
- Keep active project cap at 3.
- When cap is exceeded, archive lowest-momentum active project.
- Keep three metrics: Focus, Momentum, Progress.
- Metric explanations should be conversationally available through chat behavior.

## UI Invariants

- Keep project rail semantics: active highlighted, archived muted.
- Keep top metric strip behavior: unlabeled bars by default, tap reveals name + percentage.
- Preserve project-color stripe on messages.
- Preserve manual correction controls (rename + reassign).

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
