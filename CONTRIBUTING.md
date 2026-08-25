# Участие в разработке

## Именование коммитов

Все коммиты должны соответствовать
[Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>)!: <description>
```

- `type` обязателен и принимает одно из значений: `build`, `chore`, `ci`,
  `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.
- `scope` необязателен. Используйте строчные латинские буквы, цифры и символы
  `.`, `_`, `/`, `-`.
- `!` ставится перед `:`, если изменение нарушает обратную совместимость.
- `description` должна кратко описывать изменение.
- Полная первая строка не должна превышать 100 символов.
- Merge-коммиты не проверяются.

Примеры:

```text
feat(factory): add agent template validation
fix(installer): preserve existing symbolic links
docs: describe the release workflow
refactor(api)!: replace legacy configuration format
```

Проверить коммиты локально можно той же командой, которую использует CI:

```bash
.github/scripts/check-commit-messages.sh origin/master..HEAD
```

## Локальные проверки

Перед отправкой изменений проверьте синтаксис и dry-run установщика:

```bash
bash -n scripts/install-global.sh .github/scripts/check-commit-messages.sh
./scripts/install-global.sh all --dry-run
pwsh -NoProfile -File ./scripts/install-global.ps1 -Provider all -DryRun
```
