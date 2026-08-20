# Stacking tools

The playbooks treat stacked PRs as a concept: an ordered chain of branches where each PR targets the branch below it and lands on trunk from the bottom up. Two tools implement it. Detect which one this repo uses before running any stack operation, and use one tool per stack; never mix them on the same stack.

## Detection

1. `gh stack view --short` exits 0 → the repo uses **GitHub Stacked PRs** (`gh stack`). Exit code 9 means the extension is installed but Stacked PRs are not enabled for this repository, so treat it as unavailable here.
2. `gt log short` exits 0 in a repo with Graphite metadata → **Graphite** (`gt`).
3. Neither → plain `gh` + manual base-branch chaining: each branch's PR targets the branch below it, and you do the cascading rebases and retargets yourself.

If both tools are present, prefer whichever the existing stack was created with; for a new stack, prefer `gh stack`.

## Operation mapping

| Operation | `gh stack` | Graphite |
|---|---|---|
| Create / adopt a stack | `gh stack init [branches...]` | `gt create` per branch |
| Add a layer on top | `gh stack add <branch>` | `gt create` |
| Read topology, bottom to top | `gh stack view --json` | `gt log short --stack --reverse` |
| Push branches | `gh stack push` | `gt submit --update-only` |
| Open / update PRs | `gh stack submit --auto` | `gt submit --no-interactive` |
| Cascading rebase / restack | `gh stack rebase` | `gt restack` |
| Sync with trunk | `gh stack sync` | `gt sync` |
| Land up to a PR | `gh stack merge <pr>` (all-or-nothing, bottom-up) | `gt submit --merge-when-ready --always --update-only --no-interactive`, then the queue drains |
| Restructure | `gh stack modify` | `gt` reorder/fold commands |

## Semantic differences that change playbook behavior

- **Landing.** `gh stack merge <ceiling-pr>` is one atomic operation: every unmerged PR up to and including the ceiling merges bottom-up, or nothing does. There is no drain to watch; a failure reports back directly. Graphite's merge-when-ready is asynchronous: arm it, then watch the queue drain. Shipping's "watch the drain" steps apply only to the Graphite path.
- **Merge queues.** `gh stack merge` auto-enqueues when the base branch uses a merge queue; the queue picks the merge method and the PRs may land in separate groups.
- **Auto-merge.** Never enable plain GitHub auto-merge on individual stacked PRs managed by Graphite or by hand: children target unprotected parent branches and would merge into them immediately, collapsing the stack. `gh stack merge` is the sanctioned equivalent on the GitHub path.
- **CI and protections.** GitHub Stacked PRs runs CI and enforces branch protection against the final target branch for every PR in the stack. With Graphite or manual chaining, children are checked against their parent branch, so a green child proves less.
- **Plain-`gh` fallback.** Landing is sequential and manual: merge the bottom PR, let GitHub retarget its children (delete the merged head branch), rebase the new frontier, wait for checks, repeat. Slower, and each merge needs an active agent; say so in the reply rather than pretending it drains itself.
