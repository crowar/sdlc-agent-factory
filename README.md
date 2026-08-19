# SDLC Factory

Переиспользуемый multi-agent конвейер полного цикла разработки (SDLC):
от идеи до продакшена, затем разбор фидбека и поддержка.

Адаптирован для GitHub Copilot (VS Code custom agents + prompt files)
для запуска multi-agent workflow в VS Code.

## Что в репозитории

```text
.github/
  copilot-instructions.md        инструкции оркестратора для Copilot
  agents/                        11 специализированных ролей (*.agent.md)
  prompts/                       3 оркестраторные команды (*.prompt.md)
docs/                            артефакты пайплайна (source of truth)
```

Примечание: в текущей версии репозитория используются project-local настройки `.github/*`.

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

## 3 команды (prompt files)

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
- команды из `.github/prompts/`

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
