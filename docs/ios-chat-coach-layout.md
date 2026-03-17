# iOS Chat Coach Layout

## Purpose

Define the proposed iPhone layout for Dopamine as a ChatGPT-native coaching product.

This is a target product-layout document. The current package app is a local validation shell, not yet the final production iPhone implementation.

Important product framing:

- ChatGPT already has a Projects feature.
- Dopamine adds ongoing coaching across chats over time.
- The core job is to keep users on track, detect drift, and help them finish.

## Onboarding Surface

Before the main chat screen, first launch should include:

1. OpenAI API key entry (or skip path if local mode is available).
2. Choice to import ChatGPT share links or start fresh.
3. Optional project seed step (define goals now or infer from chat over time).

## Proposed Layout

Default screen should feel like ChatGPT iOS, with minimal additions.

```text
+----------------------------------+
| 9:41                    ...      |
| Dopamine GPT            [F]      |  <- global Focus indicator
| [P1 M:H P:4/6] [P2 M:M P:2/6] [P3 M:L P:1/6]  <- 3 active projects only
|                                  |
| (normal ChatGPT conversation)    |
| | User                           |
| | Assistant                      |
|                                  |
| Coach chip: "Momentum dipped.    |
| Want a 15-min next step?"        |
|                                  |
| [+]  Message...              [^] |
+----------------------------------+
```

### Tap-Reveal Surfaces

1. Tap focus indicator or project chip -> metrics sheet.
2. Tap project row area -> project switcher sheet.
3. Tap coach chip CTA -> actionable next-step workflow.
4. New conversation routing -> project assignment fork (stay/move/new+archive).

Metrics sheet:

```text
Focus        72  (breadth trend)
Momentum P1  61  (completion projection)
Progress P1  44  (difficulty/resources adjusted)

Improve now: [Narrow scope] [Pick priority] [Generate milestone]
```

Project switcher sheet:

```text
Active (max 3)
P1  M:H  P:4/6
P2  M:M  P:2/6
P3  M:L  P:1/6

Archived (muted list)
```

Conversation constraint:

- each conversation is linked to one project,
- a project can contain many conversations.

## Why This Over Alternatives

We evaluated dashboard-heavy and multi-pane alternatives and rejected them for default iPhone UX.

Chosen approach wins because it:

- Preserves the familiar ChatGPT interaction model (low learning cost).
- Keeps cognitive load low during conversation.
- Makes metrics available without forcing users into a "control panel."
- Keeps attention on one live conversation while still exposing project status.

Alternatives we did not choose as default:

- Full triad dashboard home: too much scanning before action.
- Timeline-first home: strong for planning, weaker for live chat continuity.
- Kanban/project-board home: increases management overhead and context switching.

## Customer Flow Priorities

The experience is optimized for users who give up early, lose track, or jump projects.

### 1) Start With Conversation, Not Setup

- After lightweight onboarding (key/import choice), user should continue chatting immediately.
- System infers or confirms project context from messages.
- Avoid heavy project-management ceremony before first value.

### 2) Keep Scope Constrained

- Only 3 active projects are visible and selectable.
- Overflow requires user-selected demotion to archive (with lowest-momentum suggested as default).
- User can still recover archived projects on demand.

### 3) Detect Drift Early

- Focus monitors topic breadth and context switching.
- Low focus triggers a short priority question before deeper assistance.

### 4) Recover Momentum Fast

- Momentum drops trigger coach nudges with concrete, small next steps.
- CTA language should be action-first ("Do 10 minutes now").

### 5) Make Progress Feel Real

- Progress considers effort realism (difficulty + resources), not just message count.
- Tap reveals "why this score" and "what increases it fastest."

### 6) PM-Style Guidance End-to-End

- Assistant acts like a pragmatic PM from ideation to productization.
- Every substantial response should end with one clear next action.

## Behavioral Contract For The Assistant

1. If focus is low, ask a prioritization question before expanding scope.
2. If momentum stalls, propose a smaller step with expected impact.
3. If progress plateaus, suggest scope cut or resource adjustment.
4. Keep tone encouraging but realistic about effort and sequencing.

## Implementation Notes

- Primary visuals should remain minimal and indicator-led.
- Labels and numeric detail are mostly hidden behind taps.
- Archived projects are intentionally de-emphasized in the default screen.
- Maintain manual correction controls (rename/reassign) for trust and recovery.
