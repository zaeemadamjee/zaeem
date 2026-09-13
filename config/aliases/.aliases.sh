# --- Aliases --- #
# --------------- #

# --- zshrc ---
# Reload zsh config. Safe to invoke from bash — switches to zsh instead of
# sourcing zsh syntax in bash (which causes the setopt/zmodload errors).
szsh() {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # shellcheck disable=SC1090
    source ~/.zshrc
  else
    if command -v zsh &>/dev/null; then
      exec zsh
    else
      echo "zsh not found — install it first" >&2
      return 1
    fi
  fi
}

# --- ls ---
alias ls='eza -A'
alias ll='eza -lAh --git'

# --- cleanup ---
alias c='clear'

# --- git ---
alias gs='git status'
alias gf='git fetch'
alias gst='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gcm='git commit -m'
alias gco='git checkout'
alias lg='lazygit'

# --- tmux ---
alias t="tmux new-session -A -s $(basename $(pwd))"
alias ta="tmux attach -t"
alias tls="tmux ls"
alias tk="tmux kill-session -t"
alias tr="tmux source-file ~/.tmux.conf"

# --- cd ---
alias ..='cd ..'
alias ...='cd ../..'

# --- claude ---
alias cc='claude'
alias ccd='claude --dangerously-skip-permissions'

# --- opencode ---
alias oc='opencode'
alias ocserve='opencode service set hostname 0.0.0.0 && opencode service set port 4096 && opencode service set password "opencode" && opencode service start'
alias ocstatus='opencode service status'
alias ocrestart='opencode service restart'
alias ocstop='opencode service stop'

# --- gcloud ---
alias gauth='gcloud auth login'