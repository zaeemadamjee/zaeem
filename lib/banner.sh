#!/usr/bin/env bash
#
# lib/banner.sh — ASCII art banner utility.
#
# Usage: source this file, then call: print_banner
#

# TTY color detection (mirrors lib/log.sh pattern)
if [[ -t 1 ]]; then
  _BANNER_COLOR='\033[2;36m'  # dim cyan
  _BANNER_RESET='\033[0m'
else
  _BANNER_COLOR=''
  _BANNER_RESET=''
fi

print_banner() {
  local lines=(
    "     ___________"
    "    / ========= \\"
    "   / ___________ \\"
    "  | _____________ |"
    "  | | >za       | |"
    "  | |           | |"
    "  | |___________| |________________________"
    "  \\=_____________/     zaeem adamjee       )"
    "  / \"\"\"\"\"\"\"\"\"\"\"\"\" \\                       /"
    " / ::::::::::::::: \\                  =D-'"
    "(___________________)"
  )

  echo ""
  for line in "${lines[@]}"; do
    printf "${_BANNER_COLOR}%s${_BANNER_RESET}\n" "$line"
    sleep 0.03
  done
  echo ""
}
