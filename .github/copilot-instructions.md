# SDLC Factory for Copilot

This workspace contains a reusable full-SDLC multi-agent pipeline for GitHub Copilot.

## Core Workflow
- Run /build-product to execute the full pipeline from idea to deployment.
- Run /process-feedback to process post-launch feedback and route actions.
- Run /maintenance-check to produce a periodic health report.

## Agents
The workflow uses custom agents in .github/agents:
- product-strategist
- spec-writer
- ux-designer
- architect
- devops
- backend-dev
- frontend-dev
- test-engineer
- reviewer
- security-auditor
- feedback-triage

## Rules
- Documentation in docs/ is the source of truth between phases.
- Keep feature scope MVP-first unless explicitly expanded.
- Use explicit user approval only during interview/discovery checkpoints.
- Use conventional commits.

## User Availability Policy
- After the task is set and the interview phase is completed, assume the user is unavailable.
- Do not pause for intermediate approvals during implementation phases.
- Continue autonomously through all remaining phases and present a single final result package.
- If a critical blocker appears, document the blocker, proposed fallback, and continue with the safest viable path.

## Skill Readiness Gate (Mandatory)
Before invoking any specialized agent:
1. Ask whether the agent has enough domain knowledge for the task.
2. If knowledge is missing or uncertain, run skill discovery first:
	- `npx skills add https://github.com/vercel-labs/skills --skill find-skills`
3. Install required focused skills before execution and document them in `docs/skills-log.md`.

## Discovery Interview Skill
For business problem clarification at pipeline start, use:
- `npx skills add https://github.com/mattpocock/skills --skill grill-me`

## Web Verification Skills
When product verification includes a web application, use:
- `npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser`
- `npx skills add https://github.com/microsoft/playwright-cli --skill playwright-cli`

## QA Skill (Optional)
For QA planning and execution support, evaluate suitability of:
- `npx skills add https://github.com/mattpocock/skills --skill qa`
