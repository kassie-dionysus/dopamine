# AGENTS.md

Instructions for coding agents working in this repository.

## Product Intent

Dopamine is a depth-first productivity chatbot.
The app should prioritize focus quality (sustained depth), momentum (small wins compounding), and practical progress (completion under constraints).

## Non-Negotiable UX Rules

- Keep the OpenAI-style two-pane layout:
  - Left: project rail.
  - Right: conversation.
- Keep the top metric strip at approximately 25% of viewport height.
- Metric bars must be unlabeled by default.
- Tapping a bar may reveal only name + percentage.
- Do not add standalone score-explanation panels in the UI; explanations belong in chat.
- Active project cap is 3; archived projects are muted gray.

## Core Behavior Rules

- Preserve top-3 active cap enforcement.
- Overflow or switch conflict should archive the lowest-momentum active project.
- Keep manual correction affordances:
  - Rename project.
  - Reassign message/project mapping.
- Maintain leader-style coaching responses: clear next step, ease signal, feasibility signal, momentum guidance.

## Technical Constraints

- Keep v1 anonymous and in-memory unless explicitly requested otherwise.
- Prefer small, testable modules under `lib/`.
- API changes should keep client contracts explicit and typed.
- Do not introduce background workers or heavy infrastructure without explicit request.

## Code Standards

- TypeScript strictness should remain enabled.
- Add/update tests when behavior changes.
- Avoid introducing broad dependencies for small utilities.
- Preserve readable, minimal interfaces.

## Validation Expectations

Before finishing work, run at minimum:

```bash
npm test
npm run build
```

If either command cannot be run, clearly state why in the final report.
