---
name: autonomous-sdlc
description: Orchestrate a complete software delivery lifecycle with real Codex subagents, durable handoffs, independent verification, and explicit authority boundaries. Use when a product or substantial feature must be delivered autonomously after discovery.
---

# Autonomous SDLC for Codex

Use Codex runtime delegation to create real subagents. Loading a role skill or writing "use agent" does not create a subagent.

## Discovery and handoff

1. Inspect the target repository before asking questions.
2. Read `sdlc.skills.yaml`. Load enabled `intake` skills in list order. A missing required skill blocks the stage before side effects; log and skip an optional missing skill.
3. Resolve purpose, users, scope, acceptance criteria, constraints, integrations, data/privacy, quality attributes, deployment, operations, authority boundaries, and exclusions.
4. Persist the result in `docs/sdlc/task-dossier.md`.
5. Ask once for confirmation of the dossier and autonomous handoff. Do not start implementation before confirmation.

After handoff, do not create routine approval checkpoints. Resolve ambiguity from the dossier, repository evidence, project conventions, authoritative evidence, then the smallest reversible option. Record material decisions in `docs/sdlc/decision-log.md`.

## Runtime subagent contract

Before execution, read [the pipeline](references/pipeline.md), [subagent routing](references/subagent-routing.md), and [optional role routing](references/role-routing.md).

- Only a runtime delegation call such as `spawn_agent` counts as a subagent.
- Before spawning, enrich the child brief from `sdlc.roles.yaml` or a bundled role brief when available. Missing role knowledge is non-blocking: log `standard_fallback` and continue with the normal stage contract.
- Give every child a bounded objective, exact inputs and outputs, allowed write scope/worktree, forbidden scope, checks, and completion contract.
- Use stable task names and track canonical agent IDs, status, ownership, attempts, gate evidence, and next action in `docs/sdlc/progress.md`.
- Use `wait_agent` to join children. Use `send_message` for added context and `followup_task` for a narrowed retry or verification pass on the same child.
- Never exceed the runtime concurrency limit. The root agent consumes one slot.
- A child final message is not gate evidence by itself; inspect artifacts and run the relevant checks.
- If runtime delegation is unavailable, report a single-agent degraded mode. Never claim that role skills or role-play produced multi-agent verification.

Parallel read-only work is safe. Parallel writers require separate worktrees and disjoint ownership. Otherwise serialize them. Only the orchestrator/integrator may write shared progress and decision logs.

An author must not approve its own work. Use independent challenger, architecture reviewer, tester, code reviewer, security reviewer, and release guardian roles as applicable.

## Completion and authority

Finish only when acceptance criteria are traceable to evidence, required checks pass, independent blockers are resolved, and deployment plus rollback instructions exist in `docs/sdlc/final-report.md`.

Do not merge protected branches, deploy, create paid resources, change DNS, or perform other external mutations unless the dossier grants that authority. If an indispensable action lacks authority, finish safe work and record `blocked_external_authority` with a resumable recipe.
