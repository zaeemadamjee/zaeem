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

agent_harness_configs_apply() {
  local repo_root="$1" mode="$2"
  local defaults_root="$repo_root/config/defaults"
  local package source_root target_rel source_file rel_path destination

  case "$mode" in
    seed|reset) ;;
    *)
      printf 'agent_harness_configs_apply: expected seed or reset, got %s\n' "$mode" >&2
      return 2
      ;;
  esac

  [[ -d "$defaults_root" ]] || {
    printf 'agent_harness_configs_apply: defaults not found: %s\n' "$defaults_root" >&2
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

      if [[ "$mode" == "seed" && ( -e "$destination" || -L "$destination" ) ]]; then
        continue
      fi

      mkdir -p "$(dirname "$destination")"
      if [[ "$mode" == "reset" && -L "$destination" ]]; then
        rm "$destination"
      fi
      cp "$source_file" "$destination"
      _agent_harness_config_log "$mode ~/$rel_path"
    done < <(find "$source_root" -type f -print0)
  done
}
