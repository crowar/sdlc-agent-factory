# Codex autonomous SDLC

## Почему прежний подход не запускал subagents

`.github/agents/*.agent.md` — declarative custom agents GitHub Copilot. Их
установка в `~/.agents/skills/<role>/SKILL.md` давала Codex инструкции роли, но
не отдельный контекст исполнения. Фразы `Use agent` и `Run in parallel` в
workflow также не являются runtime-вызовами.

Codex-native entrypoint находится в
`.codex/skills/autonomous-sdlc/SKILL.md`. Он требует реальный lifecycle:
`spawn_agent` -> track canonical ID and ownership -> `wait_agent` -> validate
artifact/evidence -> при необходимости `followup_task` тому же child.

Перед spawn orchestrator ищет специализированные знания в `sdlc.roles.yaml` и
`.github/agents/*.agent.md`. При глобальной установке эти файлы доступны как
`autonomous-sdlc/references/roles/*.agent.md`. Они добавляются к конкретному spawn
brief, но не регистрируются как отдельные skills или статические Codex agents.
Отсутствующая или повреждённая роль означает `standard_fallback`, а не остановку.

## Инварианты

- root занимает один concurrency slot; число children ограничено runtime;
- parallel read-only безопасен;
- parallel writers работают только в отдельных worktrees с disjoint ownership;
- в общем worktree writers выполняются последовательно;
- shared progress и decision logs пишет только orchestrator;
- автор не проверяет собственную работу;
- child final message не закрывает gate без проверки артефакта и evidence;
- skills/role briefs не считаются subagents;
- production/external mutations выполняются только при явной authority.

## Проверка

```bash
./scripts/validate-sdlc.sh
./scripts/install-global.sh codex --dry-run
```

CI дополнительно выполняет реальную установку в временный `HOME` и проверяет,
что установлен orchestrator с routing references, а role briefs не появились как
псевдо-agent skills.
