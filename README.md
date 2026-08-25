# SDLC Factory

Переиспользуемый multi-agent конвейер полного цикла разработки (SDLC):
от идеи до продакшена, затем разбор фидбека и поддержка.

Адаптирован для GitHub Copilot (custom agents + agent skills)
для запуска multi-agent workflow в CLI и VS Code.

## Что в репозитории

```text
.github/
  copilot-instructions.md        инструкции оркестратора для Copilot
  agents/                        11 специализированных ролей (*.agent.md)
  skills/                        3 самодостаточных workflow skills
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

Создание символических ссылок в Windows требует включённого Developer Mode или
запуска PowerShell от имени администратора. Для замены существующих файлов
передайте `-Force`.

## Codex, Gemini и Junie

Skills используют открытый формат `SKILL.md`, поэтому один и тот же workflow
устанавливается без изменения содержимого. Agents требуют адаптации формата:

| Инструмент | Skills | Agents |
|---|---|---|
| Copilot CLI | `~/.copilot/skills/` | нативно в `~/.copilot/agents/*.agent.md` |
| Codex CLI | `~/.agents/skills/` | отдельного declarative agent-формата нет; роли устанавливаются как skills |
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
`.md`. Agent-файлы используют общий frontmatter (`name` и `description`);
Copilot, Gemini и Junie применяют стандартный доступ к инструментам. Для Codex
каждая роль становится вызываемым skill, но не изолированным subagent.

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

1. Skill Readiness Gate: перед каждым агентом проверка знаний и при необходимости `find-skills`.
1. Business Interview: `grill-me` -> `docs/interview-notes.md`.
1. Discovery: `product-strategist` -> `docs/validated-idea.md`.
1. Specification and UX (параллельно): `spec-writer` + `ux-designer`.
1. Architecture: `architect` -> architecture, ADR, implementation plan, API contract, development patterns.
1. Scaffolding and GitHub: `devops`.
1. Parallel Implementation: `backend-dev` и `frontend-dev` по трекам с опорой на паттерны архитектора.
1. Testing: `test-engineer` (test cases, toolset, execution report).
1. Product Verification: для web используются `agent-browser` и `playwright-cli`.
1. Review and Security (параллельно): `reviewer` + `security-auditor`.
1. Deploy: `devops`.
1. Post-launch: `/process-feedback`, `/maintenance-check`.

Все фазы обязаны обновлять артефакты в `docs/`.

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
