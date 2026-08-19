#!/usr/bin/env bash

_agent_harness_config_target() {
  case "$1" in
    agents)   printf '%s\n' ".agents" ;;
    claude)   printf '%s\n' ".claude" ;;
    codex)    printf '%s\n' ".codex" ;;
    opencode) printf '%s\n' ".config/opencode" ;;
    *) return 1 ;;
  esac
}

_agent_harness_config_log() {
  if declare -F log_info >/dev/null 2>&1; then
    log_info "$1"
  fi
}

_agent_harness_config_detach_legacy_stow() {
  local repo_root="$1" package="$2" target_rel="$3"
  local target="$HOME/$target_rel"
  local legacy="$repo_root/config/$package/$target_rel"

  [[ -L "$target" ]] || return 0
  case "$(readlink "$target")" in
    *"config/$package/$target_rel") ;;
    *) return 0 ;;
  esac

  _agent_harness_config_log "Migrating ~/$target_rel out of the repository"
  rm "$target"
  mkdir -p "$(dirname "$target")"
  if [[ -d "$legacy" ]]; then
    mv "$legacy" "$target"
  else
    mkdir -p "$target"
  fi
}

_agent_harness_skills_mirror_claude() {
  local agents_skills="$HOME/.agents/skills"
  local claude_skills="$HOME/.claude/skills"
  local skill_dir name destination

  [[ -d "$agents_skills" ]] || return 0

  for skill_dir in "$agents_skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"
    destination="$claude_skills/$name"

    if [[ -e "$destination" || -L "$destination" ]]; then
      continue
    fi

    mkdir -p "$claude_skills"
    cp -R "$skill_dir" "$destination"
    _agent_harness_config_log "seed ~/.claude/skills/$name (mirrored from ~/.agents/skills/$name)"
  done
}

agent_harness_skills_refresh() {
  local repo_root="$1"
  local source_root="$repo_root/config/defaults/agents/.agents/skills"
  local agents_skills="$HOME/.agents/skills"
  local claude_skills="$HOME/.claude/skills"
  local skill_dir name

  [[ -d "$source_root" ]] || {
    printf 'agent_harness_skills_refresh: skills source not found: %s\n' "$source_root" >&2
    return 1
  }

  mkdir -p "$agents_skills" "$claude_skills"

  for skill_dir in "$source_root"/*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"

    rm -rf "$agents_skills/$name"
    cp -R "$skill_dir" "$agents_skills/$name"
    _agent_harness_config_log "refreshed ~/.agents/skills/$name"

    rm -rf "$claude_skills/$name"
    cp -R "$skill_dir" "$claude_skills/$name"
    _agent_harness_config_log "refreshed ~/.claude/skills/$name"
  done
}

agent_harness_configs_seed() {
  local repo_root="$1"
  local defaults_root="$repo_root/config/defaults"
  local package source_root target_rel source_file rel_path destination

  [[ -d "$defaults_root" ]] || {
    printf 'agent_harness_configs_seed: defaults not found: %s\n' "$defaults_root" >&2
    return 1
  }

  for package in agents claude codex opencode; do
    source_root="$defaults_root/$package"
    [[ -d "$source_root" ]] || continue

    target_rel="$(_agent_harness_config_target "$package")"
    _agent_harness_config_detach_legacy_stow "$repo_root" "$package" "$target_rel"

    while IFS= read -r -d '' source_file; do
      rel_path="${source_file#"$source_root/"}"
      case "$rel_path" in
        ""|/*|../*|*/../*) return 1 ;;
      esac
      destination="$HOME/$rel_path"

      if [[ -e "$destination" || -L "$destination" ]]; then
        continue
      fi

      mkdir -p "$(dirname "$destination")"
      cp "$source_file" "$destination"
      _agent_harness_config_log "seed ~/$rel_path"
    done < <(find "$source_root" -type f -print0)
  done

  _agent_harness_skills_mirror_claude
}
