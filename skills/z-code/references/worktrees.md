# Worktree layout

Repos live in `~/workspace/<repo-name>`. Worktrees for a repo live in
`~/worktrees/<repo-name>/<issue>-<branch-slug>`, one directory per branch.

## Detect before creating

Check whether you're already in a non-main worktree before creating one:

    git rev-parse --show-toplevel              # your current checkout root
    git worktree list --porcelain | head -1     # first entry is the main worktree

If the current toplevel is not the main worktree's path, you're already
isolated, Claude Code, Codex, or another harness put you here for this
session. Work in place; do not create another worktree, even if the path
doesn't match the convention below. Leave it as is.

Only apply the convention below when starting from the main checkout at
`~/workspace/<repo-name>` and no worktree exists yet for this branch. Before
creating, check for an existing one:

    git worktree list | grep <issue>-

A match means a prior or resumed session already has this branch checked
out; use that worktree instead of creating a duplicate.

## Creating

    git -C ~/workspace/<repo-name> worktree add ~/worktrees/<repo-name>/<issue>-<slug> -b <issue>-<slug>

## Removing

    git -C ~/workspace/<repo-name> worktree remove ~/worktrees/<repo-name>/<issue>-<slug>
