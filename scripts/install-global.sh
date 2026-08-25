#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROVIDERS=()
FORCE=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/install-global.sh [copilot|codex|gemini|junie|all] [--force] [--dry-run]

Link this repository's skills and agents into user-level configuration.
The default provider is copilot.

  copilot  Native agents and workflow skills
  codex    Workflow skills plus agent roles represented as skills
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
  install_workflow_skills "$HOME/.copilot/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    install_link "$source" "$HOME/.copilot/agents/$(basename "$source")"
  done
}

install_codex() {
  local source name
  install_workflow_skills "$HOME/.agents/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    name="$(basename "$source" .agent.md)"
    install_link "$source" "$HOME/.agents/skills/$name/SKILL.md"
  done
}

install_gemini() {
  local source name
  install_workflow_skills "$HOME/.gemini/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    name="$(basename "$source" .agent.md)"
    install_link "$source" "$HOME/.gemini/agents/$name.md"
  done
}

install_junie() {
  local source name
  install_workflow_skills "$HOME/.junie/skills"
  for source in "$ROOT"/.github/agents/*.agent.md; do
    name="$(basename "$source" .agent.md)"
    install_link "$source" "$HOME/.junie/agents/$name.md"
  done
}

for provider in "${PROVIDERS[@]}"; do
  "install_$provider"
done
