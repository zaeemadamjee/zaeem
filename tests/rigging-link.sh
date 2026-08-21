#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/rigging-link.XXXXXX")"
test_home="$test_root/home with spaces"
source="$repo_root/config/druk/.config/druk/config.json"
target="$test_home/.config/druk/config.json"
backup="${target}.bak"
expected='{"source":"local druk config"}'
first_output="$test_root/first-output"
second_output="$test_root/second-output"

trap 'rm -rf "$test_root"' EXIT

mkdir -p "$(dirname "$target")"
printf '%s' "$expected" > "$target"

HOME="$test_home" "$repo_root/bin/rigging" link 2>&1 | tee "$first_output"

[[ -f "$backup" ]] || { printf 'expected Druk backup at %s\n' "$backup" >&2; exit 1; }
[[ "$(<"$backup")" == "$expected" ]] || { printf 'Druk backup bytes changed\n' >&2; exit 1; }
[[ "$source" -ef "$target" ]] || { printf 'Druk config is not linked to the repository source\n' >&2; exit 1; }
! grep -Fq 'stow druk failed' "$first_output" || { printf 'first link run reported a Druk failure\n' >&2; exit 1; }

HOME="$test_home" "$repo_root/bin/rigging" link 2>&1 | tee "$second_output"

[[ "$(<"$backup")" == "$expected" ]] || { printf 'second link run changed the Druk backup bytes\n' >&2; exit 1; }
[[ "$source" -ef "$target" ]] || { printf 'second link run broke the Druk config link\n' >&2; exit 1; }
! grep -Fq 'stow druk failed' "$second_output" || { printf 'second link run reported a Druk failure\n' >&2; exit 1; }
! grep -Fq 'failure(s)' "$second_output" || { printf 'second link run was not clean\n' >&2; exit 1; }
