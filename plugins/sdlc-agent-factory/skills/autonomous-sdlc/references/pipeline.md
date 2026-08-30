# Pipeline and gates

`docs/sdlc/` is the durable handoff boundary. Every artifact records authoring role, inputs, status, evidence, and unresolved risks. `progress.md` records current stage, completed gates, active agent IDs, ownership, retry counts, and next action.

1. **Discovery — root/product strategist.** Produce and confirm `task-dossier.md`. This is the final planned user checkpoint.
2. **Specification — bounded writers plus challenger.** Produce testable requirements, stories, contracts, and UX flows. Do not start UX work from unfinished requirements: either use the confirmed dossier as its sole input or serialize it after specification. Gate: every P0 requirement is traceable and independently challenged.
3. **Architecture — architect then independent reviewer.** Produce architecture, ADRs, threat model, contracts, dependency graph, worktree/file ownership, migration, and rollback plan. Gate: no blocking contradiction.
4. **Foundation — platform/devops writer.** Establish reproducible setup, local CI-equivalent commands, secret-safe configuration, and observability baseline.
5. **Implementation — bounded implementers.** Serialize in the shared worktree. Parallelize only independent tracks in distinct worktrees with disjoint path ownership, then integrate in dependency order.
6. **System verification — independent tester.** Test requirements rather than implementation assumptions. Route failures to a targeted fixer and rerun affected plus regression checks.
7. **Review and security — independent, parallel, read-only.** Require severity and file/line evidence. The original independent reviewer verifies blocker fixes.
8. **Release readiness — independent guardian.** Verify CI evidence, artifacts, migrations, backup/restore, rollback, runbook, release notes, licenses, and known risks. Terminal state is `release_candidate_ready`, `deployed_verified` only when authorized and observed, or `blocked_external_authority`.
9. **Closeout.** Write `final-report.md` with scope, acceptance evidence, commands and results, decisions, security status, deployment/rollback, and limitations.

## Failure protocol

Preserve logs and last known-good state. Classify the failure as implementation, environment/transient, invalid plan, unmet dependency, or missing authority. Retry a child once with concrete evidence and a narrower brief. Then re-plan, reduce only non-required scope, or choose a reversible alternative. Never weaken acceptance or security gates to obtain a green status.
