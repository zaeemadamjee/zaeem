# zaeem

Personal devbox — dotfiles, toolchains, and VM provisioning.

![zaeem](assets/zaeem.png)

```
curl -fsSL https://raw.githubusercontent.com/zaeemadamjee/zaeem/main/bin/bootstrap | bash
```

## Agent harness configs

Portable defaults for Claude, Codex, OpenCode, plugins, modes, and shared skills
live in `config/defaults/`. During initial rigging, missing defaults are copied
into `~/.claude`, `~/.codex`, `~/.config/opencode`, and `~/.agents`.

Those home-directory copies are local after initialization. Re-running rigging
does not overwrite edits, sessions, authentication, caches, history, or other
runtime state.

Restore only the files managed by the repository defaults with:

```sh
rigging reset-agent-harness-configs
```

The reset preserves all unrelated files and runtime directories.
