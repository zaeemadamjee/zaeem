### Shipping

**You own what lands. Verify each PR independently, land only the verified run from the root, then keep your hands off the queue.** For "land the stack", "ship it", "enable merge when ready", or the second half of a stack that **Babysit** already drove to green.

This is the half after `playbooks/babysit.md`. Babysit makes a stack mergeable. Shipping decides what is actually safe to merge and lands it through the repo's stacking tool (`../references/stacking.md`). Green is not safe, and the gap between those two words is where this playbook lives.

1. **Verify every PR independently before arming anything.** One subagent per PR, not batched, remote/background agents when your harness offers them, each exercising the real surface (drive the browser for UIs, run the binary for CLIs) against parent versus head. Each returns `PASS`, `PASS+NOTES` or `FAIL` and posts that verdict on its own PR so the record outlives the chat. Safe means a verdict from an agent that did not write the code. CI green is not a verdict, and an approving bot review is not a verdict.
2. **Land only the contiguous verified run rooted at the bottom.** Walk up from the lowest unmerged PR and stop at the first one without a passing verdict, where both `PASS` and `PASS+NOTES` pass. A verified PR sitting above an unverified one is not landable, because merging it would pull the gap in underneath it. Report the ceiling as a PR number and say what breaks the chain.
3. **Re-check that the verdicts still describe the code.** A restack rewrites every SHA above it and silently invalidates every verdict without touching a single check. Compare `git patch-id` at the verdict SHA against the current head before trusting an older verdict, and re-verify anything that actually drifted. Twenty-one verdicts went stale this way in one run with no signal at all.
4. **Land through the stacking tool, never through per-PR auto-merge.**

   *GitHub Stacked PRs path.* `gh stack merge <ceiling-pr>` merges every unmerged PR up to and including the ceiling, bottom-up, all-or-nothing. One command, no drain. If the base branch uses a merge queue, the PRs enqueue together and may land in separate groups; watch the queue rather than assuming atomicity. A failure reports back directly; diagnose it, do not retry blind.

   *Graphite path.* Arm merge-when-ready and pass `--always`; a no-op submit skips the Graphite update and silently arms nothing, which reads exactly like success.
   ```bash
   gt submit --merge-when-ready --always --update-only --no-interactive
   ```
   Confirm arming from Graphite's own state, not from GitHub's `autoMergeRequest` field, which stays off until Graphite reaches that PR at the queue front; if you cannot confirm, say so rather than inferring it.

   *Plain-`gh` path.* Sequential and manual: merge the bottom PR, delete its head branch so GitHub retargets the children, rebase the new frontier, wait for its checks, repeat up to the ceiling. Each merge needs you active; report that cost instead of pretending it drains itself.
5. **Never enable plain GitHub auto-merge on individual stacked PRs.** Only the root targets protected trunk. Every child targets its unprotected parent branch and already reads `CLEAN`, so GitHub would merge children into parents immediately and collapse the stack into itself. The stacking tool's merge is what makes the merges sequential and safe. If a previous agent armed auto-merge, disarm with `gh pr merge <n> --disable-auto` and confirm the field is back off.
6. **Once the landing is in motion, stop touching the stack.** No sync, no restack, no speculative pushes, no stack-wide submit that reaches downstack into PRs that are mid-merge. On the Graphite path even a plain `gt submit` can retarget a base if local tracking has diverged, so never run stack commands from a worktree whose parentage you have not just checked. Independent work gets re-parented onto trunk and shipped on its own.
7. **Watch the landing, do not drive it.** On a drain or queue (Graphite, or gh-stack into a merge queue), arm the watcher in queued mode over the verified run, re-armed after any verdict you act on, until COMPLETE at the ceiling. ADVANCE is progress, not termination. Bases retarget and tool-managed refs get cut as each PR merges; that is the tool working, not damage. Report each merge and the new ceiling. If the landing stalls, diagnose before mutating, because a stalled queue and a broken stack look identical from the outside.
8. **Stop at the ceiling.** When the verified run is merged, report what landed, what the next unverified PR is, and what verifying it would take. Extending the run is a new pass through step 1, not a judgment call you make at 3am.

**Reply:** the verified run and its ceiling, each PR's verdict and who produced it, what you armed and how you confirmed it, what landed, and what the next gap needs.
