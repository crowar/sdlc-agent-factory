# Codex subagent routing

## Spawn brief

Every `spawn_agent` message must contain role and one bounded objective, exact inputs and repository/worktree path, expected return and outputs, access mode and exclusive ownership, forbidden scope, verification evidence, and completion/blocker contract.

Resolve optional role knowledge through [role-routing.md](role-routing.md) before composing the message. Do not confuse a loaded role brief with the runtime child itself.

Use a stable lowercase task name such as `spec_writer`, `ux_dossier`, `architecture_review`, `track_api`, `system_test`, or `security_review`.

## Lifecycle

1. Check dependencies, skills, capacity, and ownership.
2. Spawn independent tasks up to available child slots.
3. Record task name, canonical ID, inputs, mode, ownership, attempt, and state. The
   orchestrator may update only `docs/sdlc/progress.md` and `decision-log.md` while
   a shared-worktree child runs; those files are always forbidden to children and
   are excluded from their ownership.
4. Join with `wait_agent`; do not poll the filesystem as a substitute.
5. Validate returned artifacts and evidence before closing the gate.
6. Use `send_message` for added context. Retry author rework once with
   `followup_task`, evidence, and a narrower brief; do not create a duplicate
   child. Send completed fixes back to the original independent verifier for a
   separate recheck—fixers never verify themselves.
7. Interrupt only when the original brief is invalid or continuing is unsafe.

## Concurrency and independence

- Root plus children remain within the runtime slot limit; with four slots, spawn at most three children at once.
- Read-only analysis may run in parallel.
- Writers in one shared worktree run serially. Parallel writers require separate worktrees/branches and non-overlapping ownership recorded before spawn.
- Children never edit `docs/sdlc/progress.md` or `decision-log.md`; they return updates to the orchestrator.
- Implementers never serve as their own reviewer, security reviewer, tester, or release guardian.

## Parallel writer worktrees

The root/integrator records the base SHA, creates one branch and worktree per
independent track, and records its absolute path plus exclusive file set before
spawn. Each child works only in that worktree, runs focused checks, and commits to
its own branch. After joining all tracks, the integrator validates each result,
integrates in dependency order, records the resulting SHAs, and runs combined
contract and regression checks. Remove worktrees only after successful integration
or after preserving a resumable failure record; the integrator alone resolves
cross-track conflicts.

## Honest fallback

If `spawn_agent` is absent, continue only when the dossier permits degraded single-agent execution. Mark independent multi-agent gates as not performed and do not call role skills subagents. If independence is required, stop with a resumable capability blocker.
