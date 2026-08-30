# SDLC Factory

Переиспользуемый multi-agent конвейер полного цикла разработки (SDLC):
от идеи до продакшена, затем разбор фидбека и поддержка.

Адаптирован для GitHub Copilot и Codex. В Copilot используются declarative
custom agents; в Codex один orchestrator создаёт изолированные subagents через
runtime delegation API.

## Что в репозитории

```text
.github/
  copilot-instructions.md        инструкции оркестратора для Copilot
  agents/                        11 специализированных ролей (*.agent.md)
  skills/                        3 самодостаточных workflow skills
.codex/
  skills/autonomous-sdlc/        Codex-native orchestrator и routing protocol
.agents/plugins/marketplace.json локальный marketplace Codex
plugins/sdlc-agent-factory/      устанавливаемый Codex plugin со всеми skills
sdlc.skills.yaml                 декларативный реестр stage-specific skills
sdlc.roles.yaml                  необязательные role briefs для Codex subagents
docs/                            артефакты пайплайна (source of truth)
```

Правила подготовки изменений и соглашение об именовании коммитов описаны в
[`CONTRIBUTING.md`](CONTRIBUTING.md). GitHub Actions проверяет каждый коммит в
ветках и pull request, а также синтаксис и dry-run установщиков.

Project-local настройки `.github/*` можно установить в пользовательский профиль,
чтобы они были доступны во всех сессиях и репозиториях.

## Глобальная установка

Для GitHub Copilot CLI:

```bash
./scripts/install-global.sh copilot
```

Установщик создаёт символические ссылки:

- agents в `~/.copilot/agents/`;
- skills в `~/.copilot/skills/`.

Поэтому изменения в этом репозитории сразу доступны новым сессиям без
повторного копирования файлов. Репозиторий нельзя перемещать или удалять, пока
используются созданные ссылки.

Перезапустите Copilot CLI для загрузки agents. В уже открытой сессии skills
можно обновить командой `/skills reload`.

Существующие пользовательские файлы не перезаписываются. Для осознанного
обновления ранее установленных файлов используйте:

```bash
./scripts/install-global.sh copilot --force
```

Проверить действия без записи:

```bash
./scripts/install-global.sh all --dry-run
```

Для Windows используйте PowerShell:

```powershell
.\scripts\install-global.ps1 -Provider copilot
.\scripts\install-global.ps1 -Provider all -DryRun
```

Для изолированной проверки или собственного каталога назначения задайте
`SDLC_INSTALL_HOME`; переменная поддерживается Bash- и PowerShell-установщиками:

```powershell
$env:SDLC_INSTALL_HOME = Join-Path $env:TEMP "sdlc-agent-factory-test"
.\scripts\install-global.ps1 -Provider codex
```

Создание символических ссылок в Windows требует включённого Developer Mode или
запуска PowerShell от имени администратора. Для замены существующих файлов
передайте `-Force`.

## Codex, Gemini и Junie

Skills используют открытый формат `SKILL.md`, поэтому один и тот же workflow
устанавливается без изменения содержимого. Agents требуют адаптации формата:

| Инструмент | Skills | Agents |
|---|---|---|
| Copilot CLI | `~/.copilot/skills/` | нативно в `~/.copilot/agents/*.agent.md` |
| Codex CLI | plugin + `~/.agents/skills/` fallback | orchestrator динамически вызывает runtime subagents |
| Gemini CLI | `~/.gemini/skills/` | нативно в `~/.gemini/agents/*.md` |
| Junie CLI | `~/.junie/skills/` | нативно в `~/.junie/agents/*.md` |

Установка для конкретного инструмента или для всех сразу:

```bash
./scripts/install-global.sh codex
./scripts/install-global.sh gemini
./scripts/install-global.sh junie
./scripts/install-global.sh all
```

Gemini и Junie читают те же agent-файлы через ссылки с нативным расширением
`.md`. Agent-файлы используют общий frontmatter (`name` и `description`). Для
Codex `.github/agents` остаются библиотекой role briefs: они не устанавливаются
как псевдо-agents. Вместо этого installer помещает ссылки на них внутрь references
orchestrator'а. Перед `spawn_agent` Codex загружает подходящий brief через
`sdlc.roles.yaml`. Настоящий subagent существует только после runtime-вызова.

Если подходящей роли или файла нет, этап не блокируется: Codex записывает
`role_brief: standard_fallback`, формирует обычный bounded task из dossier и
stage gate и продолжает выполнение. Так же работают дополнительные роли,
отсутствующие в `.github/agents`, например challenger или release guardian.

## Запуск в Codex

Установите skills и перезапустите сессию Codex, чтобы обновился каталог:

```bash
./scripts/install-global.sh codex --force
```

Команда выполняет полную установку Codex за один запуск:

- регистрирует repo-local marketplace `sdlc-agent-factory-local`;
- устанавливает и включает plugin `sdlc-agent-factory`;
- устанавливает 6 skills в `~/.agents/skills` как совместимый fallback;
- добавляет role briefs оркестратору;
- проверяет наличие всех обязательных skills и статус plugin.

Установка идемпотентна: повторный запуск с `--force` обновляет ссылки и plugin.
Если `codex` отсутствует в `PATH`, обычная установка завершается ошибкой вместо
ложного сообщения об успехе. После установки откройте новую задачу Codex; если
каталог не обновился автоматически, полностью перезапустите Codex.

Проверить результат вручную:

```bash
codex plugin list
./scripts/validate-codex-plugin.sh
```

Затем попросите Codex выполнить `$autonomous-sdlc` или `$build-product`. При
наличии delegation tools orchestrator создаёт subagents, сохраняет их canonical
IDs и ownership в `docs/sdlc/progress.md`, присоединяет результаты через
`wait_agent` и независимо проверяет артефакты. Если delegation недоступен,
workflow обязан честно обозначить single-agent degraded mode.

Skills не создают subagents сами по себе. Установка нового skill во время уже
идущей сессии также не гарантирует его появление в каталоге этой сессии, поэтому
required skills проверяются до начала побочных эффектов.

## 11 агентов

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

## 3 команды (skills)

- `/build-product` — полный pipeline от идеи до deployment readiness
- `/process-feedback` — триаж фидбека и hotfix flow для P0
- `/maintenance-check` — регулярный health-check проекта

## Политика доступности пользователя

- После постановки задачи и завершения этапа интервьюирования пользователь считается недоступным.
- Пайплайн не останавливается на промежуточные подтверждения и выполняется автономно до конца.
- Пользователю предоставляется только финальный результат и итоговый пакет артефактов.
- При критическом блокере фиксируются блокер, выбранный fallback и остаточные риски.

## Запуск в GitHub Copilot (рекомендуется)

1. Откройте этот репозиторий в VS Code.
1. Убедитесь, что включен GitHub Copilot Chat.
1. Откройте Chat и введите:

```text
/build-product
```

1. Передайте идею продукта одной строкой.

Copilot подхватит:

- `.github/copilot-instructions.md`
- агентов из `.github/agents/`
- workflows из `.github/skills/`

Skills работают как slash-команды в Agent mode, включая Agent Host.

## Как проходит пайплайн

1. Preflight: проверка `sdlc.skills.yaml`, обязательных skills, delegation capability и authority boundaries.
1. Business Interview и единый autonomous handoff -> `docs/sdlc/task-dossier.md`.
1. Discovery и challenge требований реальными bounded subagents.
1. Specification и UX: параллельно только от общего dossier либо последовательно при зависимости UX от requirements.
1. Architecture: `architect` -> architecture, ADR, implementation plan, API contract, development patterns.
1. Scaffolding and GitHub: `devops`.
1. Implementation: последовательно в общем worktree либо параллельно в отдельных worktrees с непересекающимся ownership.
1. Testing: `test-engineer` (test cases, toolset, execution report).
1. Product Verification: для web используются `agent-browser` и `playwright-cli`.
1. Review and Security (параллельно, read-only): независимые `reviewer` + `security-auditor`.
1. Release guardian: `release_candidate_ready`, авторизованный `deployed_verified` или `blocked_external_authority`.
1. Post-launch: `/process-feedback`, `/maintenance-check`.

Все фазы используют `docs/sdlc/` как durable handoff. Общие progress и decision
logs изменяет только orchestrator.

## Обязательные навыки и рекомендации

- Discovery interview:
  - `npx skills add https://github.com/mattpocock/skills --skill grill-me`
- Skill discovery (если у агента недостаточно знаний):
  - `npx skills add https://github.com/vercel-labs/skills --skill find-skills`
- Web verification (если продукт web):
  - `npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser`
  - `npx skills add https://github.com/microsoft/playwright-cli --skill playwright-cli`
- QA support (опционально):
  - `npx skills add https://github.com/mattpocock/skills --skill qa`
