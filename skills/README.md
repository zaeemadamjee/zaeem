# skills

Agent skills, seeded into `~/.agents/skills` and `~/.claude/skills`. Most are adapted from [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack), rewritten to be harness-neutral.

```
rigging skills   # force re-copy from this folder into both targets
```

Invoke any skill with a slash command, e.g. `/z-code`, `/no-comments`, `/unslop`.

## z-code

`/z-code` is the umbrella skill. It sets the working style (concise replies, simple code, no narrating comments, verified work) and routes tasks to a matching playbook in `z-code/playbooks/`. It leans on three groups of supporting skills:

- **Principles.** 21 `principle-*` leaf skills (laziness protocol, model the domain, prove it works, ...). z-code cites the ones that shaped each decision.
- **Workflow.** `how` (explain a subsystem), `why` (recover the rationale behind code), `architect` (design before implementing), `arena` (N parallel attempts, pick and graft), `swarm`, `interrogate` (adversarial review), `reflect`, `figure-it-out`, `show-me-your-work`, `tdd`.
- **Code quality.** `no-comments` (delete narrating comments), `unslop` (de-slop prose), `technical-writing` (docs, PR descriptions, commits), `typescript-best-practices`.

Stacked-PR playbooks (babysit, shipping, autopilot) auto-detect the stacking tool per repo: `gh stack`, then Graphite, then plain `gh`. See `z-code/references/stacking.md`.

### Examples

```
/z-code add rate limiting to the upload endpoint
```
Runs the Feature playbook. Names the data shape first, designs through `architect` if the change crosses a function boundary, delegates implementation, and proves it works against the real artifact before replying.

```
/z-code why does this retry loop cap at 3? are we sure that's right?
```
Runs Investigation. `why` digs through git history, PRs, and any connected trackers for the original rationale and answers with citations instead of guesses.

```
/z-code check on PR 412
```
Runs the Babysit playbook in `check` mode. One status pass with the watcher script and a report of conflicts, review threads, and CI.

```
/z-code land the stack
```
Runs Shipping. Every PR gets an independent verification verdict, then only the contiguous verified run from the root lands, via `gh stack merge` or Graphite merge-when-ready.

Individual skills also work standalone:

```
/no-comments            # strip narrating comments from the current diff
/how does auth work?    # architectural walkthrough of a subsystem
/interrogate            # multi-perspective adversarial review before shipping
```

## Adding a skill

Create `skills/<name>/SKILL.md` with `name` and `description` frontmatter, then run `rigging skills`. For anything non-trivial, follow `z-code/playbooks/authoring-a-skill.md`.
