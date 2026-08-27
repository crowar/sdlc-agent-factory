#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/.codex/skills/autonomous-sdlc/SKILL.md"
PIPELINE="$ROOT/.codex/skills/autonomous-sdlc/references/pipeline.md"
ROUTING="$ROOT/.codex/skills/autonomous-sdlc/references/subagent-routing.md"
ROLE_ROUTING="$ROOT/.codex/skills/autonomous-sdlc/references/role-routing.md"
REGISTRY="$ROOT/sdlc.skills.yaml"
ROLE_REGISTRY="$ROOT/sdlc.roles.yaml"

for file in "$SKILL" "$PIPELINE" "$ROUTING" "$ROLE_ROUTING" "$REGISTRY" "$ROLE_REGISTRY"; do
  [[ -s "$file" ]] || { printf 'missing or empty: %s\n' "$file" >&2; exit 1; }
done

head -n 1 "$SKILL" | grep -qx -- '---'
grep -q '^name: autonomous-sdlc$' "$SKILL"
grep -q '^description: ' "$SKILL"
grep -q 'path: .codex/skills/autonomous-sdlc/SKILL.md' "$REGISTRY"
grep -q 'path: .codex/skills/grill-me/SKILL.md' "$REGISTRY"
grep -q 'path: .codex/skills/grilling/SKILL.md' "$REGISTRY"

while IFS= read -r path; do
  [[ -f "$ROOT/$path" ]] || { printf 'registry path missing: %s\n' "$path" >&2; exit 1; }
done < <(sed -n 's/^[[:space:]]*path:[[:space:]]*//p' "$REGISTRY")

while IFS= read -r path; do
  [[ -f "$ROOT/$path" ]] || { printf 'role path missing: %s\n' "$path" >&2; exit 1; }
done < <(sed -n 's/^[[:space:]]*path:[[:space:]]*//p' "$ROLE_REGISTRY")

for token in spawn_agent wait_agent followup_task; do
  grep -q "$token" "$ROUTING" "$SKILL"
done

for token in 'separate worktrees' 'read-only' 'single-agent degraded' 'blocked_external_authority'; do
  grep -q "$token" "$SKILL" "$PIPELINE" "$ROUTING"
done

grep -q 'standard_fallback' "$SKILL" "$ROLE_ROUTING"
grep -q 'Missing role knowledge is non-blocking' "$SKILL"

printf 'SDLC skill and routing contract are valid\n'
