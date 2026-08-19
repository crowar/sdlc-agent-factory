---
name: maintenance-check
description: Run periodic project health checks and write maintenance report.
agent: agent
---

Run periodic maintenance checks on the codebase.

## PROCESS
1. Run dependency vulnerability checks.
2. Check outdated dependencies.
3. Find unresolved TODO/FIXME markers.
4. Run full test suite.
5. Run performance/accessibility audits where applicable.
6. Check bundle size budget.
7. Review docs/backlog.md for overdue items.

## OUTPUT: docs/maintenance-report.md
- Dependency health.
- Test health.
- Performance health.
- Tech debt.
- Recommended actions prioritized by risk.

Suggest a cadence: weekly or before each release.
