# Build Product Workflow

Drive the user's idea through discovery, specification, architecture, implementation, independent verification, and release handoff.

For Codex, `.codex/skills/autonomous-sdlc/SKILL.md` and its references are the normative execution protocol. Use runtime `spawn_agent` and join operations for real subagents; loading `.github/agents/*.agent.md` or an installed role skill only provides a role brief.

## Setup and handoff

- Create durable state under `docs/sdlc/`: `task-dossier.md`, `progress.md`, `decision-log.md`, and `final-report.md`.
- Perform one complete business interview and confirm the dossier once.
- After confirmation, assume the user is unavailable for ordinary decisions.
- Load enabled stage skills from `sdlc.skills.yaml` in order. Missing required skills fail closed before side effects; optional skills are logged and skipped.

## Agent routing

- The orchestrator assesses readiness before spawn; it does not ask a nonexistent child whether it has enough knowledge.
- Each child receives a bounded task with exact inputs, output contract, access mode, ownership, forbidden scope, checks, and completion criteria.
- Enrich that task from `sdlc.roles.yaml` or a bundled `.github/agents` role brief when available. A missing role is logged as `standard_fallback` and never blocks the stage.
- Track canonical agent IDs, attempts, ownership, status, evidence, and next action in `docs/sdlc/progress.md`.
- Join children and inspect their artifacts. Retry once through the same child with evidence and a narrower brief, then re-plan.
- Parallelize only independent read-only work or disjoint writers in separate worktrees. Serialize writers in a shared worktree.
- Only the orchestrator updates shared progress and decision logs.
- An author cannot approve its own work. Reviewer, security, test, architecture review, and release guardian roles must be independent.

## Stages

1. Discovery and confirmed autonomous handoff.
2. Testable specification, UX, and an independent ambiguity challenge.
3. Architecture, threat model, implementation ownership, rollback, and independent architecture review.
4. Reproducible scaffold and CI-equivalent local checks.
5. Dependency-ordered implementation with focused tests.
6. Independent system verification against acceptance criteria.
7. Parallel read-only correctness and security reviews; targeted fixes and recheck.
8. Independent release guardian verdict.
9. Final report and resumable handoff.

Deployment, protected-branch changes, paid resources, DNS, or other external mutations require explicit authority. Otherwise finish a release candidate or use `blocked_external_authority`; never claim an unverified deployment.

If Codex delegation is unavailable, state that execution is single-agent degraded mode. Never report role-play or role skills as completed multi-agent work.
