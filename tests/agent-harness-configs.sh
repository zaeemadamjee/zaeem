#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/agent-harness-configs.sh
source "$REPO_ROOT/lib/agent-harness-configs.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fixture="$tmp/repo"
export HOME="$tmp/home"
mkdir -p \
  "$fixture/config/defaults/claude/.claude" \
  "$fixture/config/defaults/codex/.codex" \
  "$fixture/config/defaults/opencode/.config/opencode/modes" \
  "$fixture/config/defaults/agents/.agents/skills/example" \
  "$HOME"

printf 'claude-default\n' > "$fixture/config/defaults/claude/.claude/settings.json"
printf 'codex-default\n' > "$fixture/config/defaults/codex/.codex/config.toml"
printf 'opencode-default\n' > "$fixture/config/defaults/opencode/.config/opencode/opencode.json"
printf 'mode-default\n' > "$fixture/config/defaults/opencode/.config/opencode/modes/review.md"
printf 'skill-default\n' > "$fixture/config/defaults/agents/.agents/skills/example/SKILL.md"

assert_content() {
  local expected="$1" file="$2" actual
  actual="$(cat "$file")"
  [[ "$actual" == "$expected" ]] || {
    printf 'expected %s in %s, got %s\n' "$expected" "$file" "$actual" >&2
    exit 1
  }
}

agent_harness_configs_apply "$fixture" seed
assert_content "claude-default" "$HOME/.claude/settings.json"
assert_content "codex-default" "$HOME/.codex/config.toml"
assert_content "mode-default" "$HOME/.config/opencode/modes/review.md"
assert_content "skill-default" "$HOME/.agents/skills/example/SKILL.md"

printf 'local-edit\n' > "$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude/sessions"
printf 'runtime\n' > "$HOME/.claude/sessions/keep"
printf 'unrelated\n' > "$HOME/.config/opencode/local.json"
printf 'new-default\n' > "$fixture/config/defaults/claude/.claude/settings.json"

agent_harness_configs_apply "$fixture" seed
assert_content "local-edit" "$HOME/.claude/settings.json"

agent_harness_configs_apply "$fixture" reset
assert_content "new-default" "$HOME/.claude/settings.json"
assert_content "runtime" "$HOME/.claude/sessions/keep"
assert_content "unrelated" "$HOME/.config/opencode/local.json"

legacy_fixture="$tmp/legacy-repo"
export HOME="$tmp/legacy-home"
mkdir -p \
  "$legacy_fixture/config/defaults/claude/.claude" \
  "$legacy_fixture/config/defaults/agents/.agents/skills/example" \
  "$legacy_fixture/config/claude/.claude/sessions" \
  "$HOME"
printf 'default\n' > "$legacy_fixture/config/defaults/claude/.claude/settings.json"
printf 'skill\n' > "$legacy_fixture/config/defaults/agents/.agents/skills/example/SKILL.md"
printf 'legacy-runtime\n' > "$legacy_fixture/config/claude/.claude/sessions/keep"
ln -s "$legacy_fixture/config/claude/.claude" "$HOME/.claude"
ln -s "$legacy_fixture/config/agents/.agents" "$HOME/.agents"

agent_harness_configs_apply "$legacy_fixture" seed
[[ ! -L "$HOME/.claude" ]]
[[ ! -L "$HOME/.agents" ]]
assert_content "legacy-runtime" "$HOME/.claude/sessions/keep"
assert_content "default" "$HOME/.claude/settings.json"
assert_content "skill" "$HOME/.agents/skills/example/SKILL.md"

printf 'agent harness config checks passed\n'
