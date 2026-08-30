#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_HOME="${SDLC_INSTALL_HOME:-$HOME}"
PROVIDERS=()
FORCE=0
DRY_RUN=0
CODEX_PLUGIN_NAME="sdlc-agent-factory"
CODEX_MARKETPLACE_NAME="sdlc-agent-factory-local"

usage() {
  cat <<'EOF'
Usage: scripts/install-global.sh [copilot|codex|gemini|junie|all] [--force] [--dry-run]

Link this repository's skills and agents into user-level configuration.
The default provider is copilot.

  copilot  Native agents and workflow skills
  codex    Workflow skills plus the Codex-native subagent orchestrator
  gemini   Native subagents and workflow skills
  junie    Native subagents and workflow skills
  all      Install for every provider

Existing files are never replaced unless --force is supplied.
EOF
}

for arg in "$@"; do
  case "$arg" in
    copilot|codex|gemini|junie) PROVIDERS+=("$arg") ;;
    all) PROVIDERS=(copilot codex gemini junie) ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

if ((${#PROVIDERS[@]} == 0)); then
  PROVIDERS=(copilot)
fi

install_link() {
  local source="$1"
  local destination="$2"
  local current_target

  if [[ -L "$destination" ]]; then
    current_target="$(readlink "$destination")"
    if [[ "$current_target" == "$source" ]]; then
      printf 'unchanged %s\n' "$destination"
      return
    fi
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      printf 'refusing to replace %s (use --force)\n' "$destination" >&2
      return 1
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'would replace %s -> %s\n' "$destination" "$source"
      return
    fi
    rm -f "$destination"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'would link %s -> %s\n' "$destination" "$source"
    return
  fi

  mkdir -p "$(dirname "$destination")"
  ln -s "$source" "$destination"
  printf 'linked %s -> %s\n' "$destination" "$source"
}

install_workflow_skills() {
  local destination_root="$1"
  local skill source

  for source in "$ROOT"/.github/skills/*; do
    skill="$(basename "$source")"
    install_link "$source/SKILL.md" "$destination_root/$skill/SKILL.md"
    install_link "$source/workflow.md" "$destination_root/$skill/workflow.md"
  done
}

install_copilot() {
  local source
  install_workflow_skills "$TARGET_HOME/.copilot/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    install_link "$source" "$TARGET_HOME/.copilot/agents/$(basename "$source")"
  done
}

install_codex() {
  local skill_dir source relative skill role
  "$ROOT/scripts/validate-codex-plugin.sh"
  install_workflow_skills "$TARGET_HOME/.agents/skills"
  for skill_dir in "$ROOT"/.codex/skills/*; do
    skill="$(basename "$skill_dir")"
    while IFS= read -r source; do
      relative="${source#"$skill_dir/"}"
      install_link "$source" "$TARGET_HOME/.agents/skills/$skill/$relative"
    done < <(find "$skill_dir" -type f -print)
  done
  for source in "$ROOT"/.github/agents/*.agent.md; do
    role="$(basename "$source" .agent.md)"
    install_link "$source" "$TARGET_HOME/.agents/skills/autonomous-sdlc/references/roles/$role.agent.md"
  done

  verify_codex_skills
  install_codex_plugin
}

verify_codex_skills() {
  local skill

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'would verify required Codex skills in %s\n' "$TARGET_HOME/.agents/skills"
    return
  fi

  for skill in autonomous-sdlc build-product grill-me grilling maintenance-check process-feedback; do
    if [[ ! -f "$TARGET_HOME/.agents/skills/$skill/SKILL.md" ]]; then
      printf 'missing required Codex skill after installation: %s\n' "$skill" >&2
      return 1
    fi
  done
  printf 'verified 6 required Codex skills\n'
}

install_codex_plugin() {
  local plugin_list

  if [[ ! -f "$ROOT/.agents/plugins/marketplace.json" ||
        ! -f "$ROOT/plugins/$CODEX_PLUGIN_NAME/.codex-plugin/plugin.json" ]]; then
    printf 'Codex plugin package is incomplete; run scripts/validate-codex-plugin.sh\n' >&2
    return 1
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'would register Codex marketplace %s\n' "$ROOT"
    printf 'would install Codex plugin %s@%s\n' "$CODEX_PLUGIN_NAME" "$CODEX_MARKETPLACE_NAME"
    return
  fi

  if ! command -v codex >/dev/null 2>&1; then
    if [[ -n "${SDLC_INSTALL_HOME:-}" ]]; then
      printf 'skipped Codex plugin registration in isolated install: codex CLI not found\n'
      return
    fi
    printf 'codex CLI is required to register the plugin but was not found in PATH\n' >&2
    return 1
  fi

  if [[ -n "${CODEX_HOME:-}" ]]; then
    mkdir -p "$CODEX_HOME"
  fi

  codex plugin marketplace add "$ROOT" --json
  codex plugin add "$CODEX_PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" --json
  plugin_list="$(codex plugin list)"
  if ! grep -F "$CODEX_PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" <<<"$plugin_list" | grep -Fq 'installed, enabled'; then
    printf 'Codex plugin installation could not be verified\n%s\n' "$plugin_list" >&2
    return 1
  fi
  printf 'verified Codex plugin %s@%s\n' "$CODEX_PLUGIN_NAME" "$CODEX_MARKETPLACE_NAME"
}

install_gemini() {
  local source name
  install_workflow_skills "$TARGET_HOME/.gemini/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    name="$(basename "$source" .agent.md)"
    install_link "$source" "$TARGET_HOME/.gemini/agents/$name.md"
  done
}

install_junie() {
  local source name
  install_workflow_skills "$TARGET_HOME/.junie/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    name="$(basename "$source" .agent.md)"
    install_link "$source" "$TARGET_HOME/.junie/agents/$name.md"
  done
}

for provider in "${PROVIDERS[@]}"; do
  "install_$provider"
done
