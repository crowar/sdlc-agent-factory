#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <git-revision-range>" >&2
  exit 2
fi

range="$1"
commit_list="$(git rev-list --reverse --no-merges "$range")"

if [[ -z "$commit_list" ]]; then
  echo "No non-merge commits to validate."
  exit 0
fi

pattern='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9][a-z0-9._/-]*\))?(!)?: [^[:space:]].*$'
errors=0

while IFS= read -r commit; do
  subject="$(git show -s --format=%s "$commit")"

  if [[ ! "$subject" =~ $pattern ]]; then
    printf 'Invalid commit message: %s %s\n' "${commit:0:12}" "$subject" >&2
    errors=$((errors + 1))
    continue
  fi

  if [[ "${#subject}" -gt 100 ]]; then
    printf 'Commit subject exceeds 100 characters: %s %s\n' \
      "${commit:0:12}" "$subject" >&2
    errors=$((errors + 1))
  fi
done <<< "$commit_list"

if [[ "$errors" -gt 0 ]]; then
  cat >&2 <<'EOF'

Use Conventional Commits:
  <type>(<scope>)!: <description>

Examples:
  feat(factory): add agent template validation
  fix(installer): preserve existing symbolic links
  docs: describe the release workflow

See CONTRIBUTING.md for the complete convention.
EOF
  exit 1
fi

echo "All commit messages follow the convention."
