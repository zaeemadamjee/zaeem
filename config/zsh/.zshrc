# --- Guard: prevent sourcing zsh config from bash/sh (e.g. `szsh` from bash) ---
# If this file is sourced by bash, ZSH_VERSION will be unset. Fail fast with a
# helpful message and switch to zsh instead of spewing setopt/zmodload errors.
if [[ -z "${ZSH_VERSION:-}" ]]; then
  _cur_shell="${0##*/}"
  # $0 is often `-bash` or `bash` when sourced from bash; fall back to $SHELL for display
  echo "zshrc: not running under zsh (current: ${_cur_shell:-${SHELL:-unknown}}). Switching to zsh..." >&2
  if command -v zsh &>/dev/null; then
    exec zsh
  fi
  return 0 2>/dev/null || exit 0
fi

# --- PATH: tool install dirs (must come before welcome so rigging --check finds them) ---
export PATH="$HOME/.local/bin:$PATH"           # claude code
export PATH="$HOME/.opencode/bin:$PATH"        # opencode
export PATH="$HOME/.npm-global/bin:$PATH"      # npm globals
export PATH="$HOME/.bun/bin:$PATH"             # bun
export PATH="$HOME/.cargo/bin:$PATH"           # rust/cargo
export PATH="$PATH:$HOME/go/bin"               # go workspace binaries

# --- Editor ---
export EDITOR="druk"
export VISUAL="druk"

# --- Browser (headless OAuth: print URL instead of failing to open a display) ---
# OpenCode and other tools call xdg-open for OAuth flows; the shim at
# ~/.local/bin/xdg-open (installed by rigging tools) delegates to $BROWSER.
export BROWSER="$HOME/zaeem/devbox/bin/browser"

# --- SSH agent forwarding (stable socket so tmux panes stay connected) ---
# Must run before tmux attach so the symlink is fresh when we re-enter an existing session.
if [[ -n "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]]; then
  ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
fi
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# --- Welcome screen + tmux attach (SSH login only, not already inside tmux) ---
# Placed early so exec tmux short-circuits the rest of zshrc on initial SSH login —
# devbox/starship/etc only need to init inside tmux sessions, not the throwaway
# pre-tmux shell. PATH is set above so rigging --check can find all tools.
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && [[ -t 0 ]]; then
  if [[ -z "${WELCOME_SHOWN:-}" ]]; then
    [[ -f "$HOME/zaeem/devbox/bin/welcome" ]] && source "$HOME/zaeem/devbox/bin/welcome"
  else
    exec tmux new-session -A -s main
  fi
fi

# --- History ---
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt HIST_VERIFY

# --- Options ---
setopt AUTO_CD
setopt CORRECT

# --- Aliases ---
source ~/.aliases.sh
alias rigging='bash ~/zaeem/devbox/bin/rigging'
alias shutdown='sudo poweroff'

# --- Homebrew (manages python, go, rust, etc.) ---
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
[[ -f "${BREW_PREFIX}/bin/brew" ]] && eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

# --- bun (installed via pkgs/lang/bun) ---
export BUN_INSTALL="$HOME/.bun"

# --- nvm (installed via pkgs/lang/node) ---
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]]          && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# --- pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# --- Prompt (after Homebrew so starship is in PATH) ---
eval "$(starship init zsh)"


# --- Secrets (copied from local devbox/profiles/<name>.env by bin/start) ---
# set -a auto-exports every variable defined during the source so subprocesses
# (opencode, claude, etc.) inherit them without needing explicit `export` in the file.
if [ -f "$HOME/.config/secrets.env" ]; then
  set -a
  source "$HOME/.config/secrets.env"
  set +a
fi

# --- Rust/cargo (env sets CARGO_HOME etc, PATH already includes ~/.cargo/bin above) ---
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# --- fzf ---
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- zoxide (smart cd) ---
eval "$(zoxide init zsh)"

# --- atuin (shell history) ---
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

