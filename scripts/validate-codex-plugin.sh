#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$ROOT/plugins/sdlc-agent-factory"
MARKETPLACE="$ROOT/.agents/plugins/marketplace.json"

compare_tree() {
  local source_root="$1"
  local plugin_root="$2"
  local source relative

  while IFS= read -r source; do
    relative="${source#"$source_root/"}"
    if [[ ! -f "$plugin_root/$relative" ]]; then
      printf 'plugin is missing %s\n' "$plugin_root/$relative" >&2
      return 1
    fi
    if ! cmp -s "$source" "$plugin_root/$relative"; then
      printf 'plugin copy is stale: %s\n' "$plugin_root/$relative" >&2
      return 1
    fi
  done < <(find "$source_root" -type f -print | sort)
}

for skill in build-product maintenance-check process-feedback; do
  compare_tree "$ROOT/.github/skills/$skill" "$PLUGIN/skills/$skill"
done

for skill in autonomous-sdlc grill-me grilling; do
  while IFS= read -r source; do
    relative="${source#"$ROOT/.codex/skills/$skill/"}"
    [[ "$relative" == references/roles/* ]] && continue
    test -f "$PLUGIN/skills/$skill/$relative"
    cmp -s "$source" "$PLUGIN/skills/$skill/$relative" || {
      printf 'plugin copy is stale: %s\n' "$PLUGIN/skills/$skill/$relative" >&2
      exit 1
    }
  done < <(find "$ROOT/.codex/skills/$skill" -type f -print | sort)
done

for source in "$ROOT"/.github/agents/*.agent.md; do
  destination="$PLUGIN/skills/autonomous-sdlc/references/roles/$(basename "$source")"
  test -f "$destination"
  cmp -s "$source" "$destination" || {
    printf 'plugin role copy is stale: %s\n' "$destination" >&2
    exit 1
  }
done

ruby -rjson -e '
  plugin = JSON.parse(File.read(ARGV[0]))
  market = JSON.parse(File.read(ARGV[1]))
  abort "invalid plugin name" unless plugin["name"] == "sdlc-agent-factory"
  abort "invalid skills path" unless plugin["skills"] == "./skills/"
  abort "invalid marketplace name" unless market["name"] == "sdlc-agent-factory-local"
  entry = market.fetch("plugins").find { |candidate| candidate["name"] == plugin["name"] }
  abort "missing marketplace entry" unless entry
  abort "plugin is not installed by default" unless entry.dig("policy", "installation") == "INSTALLED_BY_DEFAULT"
' "$PLUGIN/.codex-plugin/plugin.json" "$MARKETPLACE"

skill_count="$(find "$PLUGIN/skills" -name SKILL.md -type f | wc -l | tr -d ' ')"
if [[ "$skill_count" != 6 ]]; then
  printf 'expected 6 plugin skills, found %s\n' "$skill_count" >&2
  exit 1
fi

printf 'validated Codex plugin with 6 synchronized skills\n'
