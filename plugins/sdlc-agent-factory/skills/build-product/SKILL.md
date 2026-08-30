---
name: build-product
description: Run the full SDLC pipeline from raw idea to deployment readiness, using real runtime subagents when Codex delegation is available.
---

# Build Product

Execute the reusable SDLC pipeline described in [the bundled workflow](workflow.md).

Treat the user's message as the product idea and follow the prompt's phases, artifacts, agent routing, approval policy, and completion report requirements.

In Codex, first read `.codex/skills/autonomous-sdlc/SKILL.md` and its linked references when they exist in the active project. Use `sdlc.roles.yaml` to enrich spawned children from `.github/agents` when available. A role brief is optional and is not a subagent; if it is missing, continue with the standard bounded task. Create independent execution only through the Codex runtime delegation tools described by that orchestrator.
