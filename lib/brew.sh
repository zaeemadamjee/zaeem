#!/usr/bin/env bash
#
# Shared Homebrew helpers — sourced by bin/rigging and devbox/bin/rigging.
# Requires lib/log.sh to be sourced first.
#

_tap_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS= read -r tap || [[ -n "$tap" ]]; do
    [[ -z "$tap" || "$tap" =~ ^# ]] && continue
    log_dim "Tapping $tap..."
    brew tap "$tap" </dev/null || log_warn "Failed to tap $tap"
  done <"$file"
}

_install_from_file() {
  local file="$1" flag="${2:-}"
  [[ -f "$file" ]] || { log_error "File not found: $file"; return 1; }
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    log_dim "Installing $pkg..."
    # shellcheck disable=SC2086
    brew install $flag "$pkg" </dev/null \
      || { log_warn "Failed to install $pkg"; _track_failed "brew $pkg"; }
  done <"$file"
}
