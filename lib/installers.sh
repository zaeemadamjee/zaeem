#!/usr/bin/env bash
#
# Upstream curl installers for tools we don't take from Homebrew taps —
# sourced by bin/rigging and devbox/bin/rigging.
# Requires lib/log.sh and a _track_failed function.
#

# opencode 2 has its own installer; the classic opencode.ai/install refuses 2.x.
# Reinstalls over an existing 1.x so the default is always major version 2.
install_opencode() {
  local bin
  bin="$(command -v opencode || echo "$HOME/.opencode/bin/opencode")"
  if [[ "$("$bin" --version 2>/dev/null)" =~ (^|[[:space:]])v?2\. ]]; then
    log_info "opencode: already installed"
    return
  fi
  log_info "opencode: installing v2..."
  curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path \
    && log_ok "opencode" \
    || { log_warn "opencode install failed"; _track_failed "opencode"; }
}

# Installs to ~/.druk/bin; PATH is set by the managed shell config.
install_druk() {
  if command -v druk &>/dev/null || [[ -x "$HOME/.druk/bin/druk" ]]; then
    log_info "druk: already installed"
    return
  fi
  log_info "druk: installing..."
  curl -fsSL https://druk.sh/install | bash -s -- --no-modify-path \
    && log_ok "druk" \
    || { log_warn "druk install failed"; _track_failed "druk"; }
}
