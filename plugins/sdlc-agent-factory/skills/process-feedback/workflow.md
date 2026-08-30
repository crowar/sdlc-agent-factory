# Process Feedback Workflow

Process user feedback and convert it into prioritized actions.

Assume the user may be unavailable while this flow is running.
Do not block on interactive approvals. Proceed with the safest default actions and report outcomes.

## PROCESS
1. Use feedback-triage to categorize and prioritize feedback.
2. If P0 bugs exist, immediately flag them to the user.
3. Show summary counts: bugs, feature requests, UX issues.
4. Start fixing P0 bugs immediately unless an explicit policy forbids hotfixes.

For P0 bugs:
1. Create a hotfix branch from main.
2. Use backend-dev or frontend-dev to fix.
3. Use test-engineer to add regression tests.
4. Create PR directly to main.

For prioritized feature requests:
- Run mini-pipeline: spec-writer -> architect -> implementation -> test-engineer -> reviewer.
- Merge through develop then main.
