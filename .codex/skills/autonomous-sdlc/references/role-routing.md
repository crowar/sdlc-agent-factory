# Optional role knowledge

Role files enrich a subagent brief; they do not create a subagent and their absence
must never block the SDLC stage.

## Resolution order

For the requested stage and role:

1. Read `sdlc.roles.yaml` from the target repository when present. Select the first
   enabled matching role and stage, then resolve its path from the repository root.
2. If the registry or path is absent, look for a matching bundled brief under
   `references/roles/<role>.agent.md` relative to this skill. Global installation
   places the shared `.github/agents` briefs there.
3. If no brief exists, continue with standard process knowledge and the bounded
   spawn contract. Record `role_brief: standard_fallback` in progress; do not skip
   the stage, weaken its gate, or ask the user to provide an agent.

Unknown roles such as specification challenger, architecture reviewer, or release
guardian normally use the standard fallback unless a project adds an entry.

## Composing the spawn message

Treat the role file as specialized knowledge, not as the complete task. Compose the
child message from:

1. the selected role brief, excluding provider-specific invocation syntax;
2. the stage objective and exact input artifacts;
3. expected output or read-only return contract;
4. worktree and exclusive ownership;
5. forbidden shared files and external actions;
6. verification evidence and completion/blocker conditions.

The task-specific contract and confirmed dossier override a conflicting generic
role brief. A missing or malformed optional role is logged and ignored. Retry or
replace the role file only when convenient; continue using the standard fallback.
