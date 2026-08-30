---
name: grilling
description: Interview the user in dependency-aware rounds until a product idea, plan, or design has no unresolved decision frontier.
---

Map the subject as a design tree: each decision branches into decisions that depend on it. In every round, ask the whole current frontier—only questions whose prerequisites are settled. Number the questions and include a recommended answer. Recompute the frontier from the answers before the next round.

Discover facts from the repository, tools, or bounded read-only subagents instead of asking the user. The user decides preferences, product scope, authority, and tradeoffs that evidence cannot settle.

Persist settled decisions, assumptions, risks, authority boundaries, and the open frontier in `docs/sdlc/task-dossier.md`. Finish only when the frontier is empty and the user confirms the dossier and autonomous handoff.
