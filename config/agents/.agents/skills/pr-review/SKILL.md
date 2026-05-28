---
name: pr-review
description: >
  Pull, review, test, and summarize a GitHub pull request. Use when asked to
  review a PR, given a PR URL or number. Gathers context from the codebase,
  Linear, Notion, and Slack, then produces a structured review.
---

# PR Review

## Mindset

**Disregard all prior conversation context.** Base this review solely on what
you gather during the steps below — the diff, the codebase, Linear, Notion,
Slack, and browser exploration. Do not carry forward assumptions, opinions, or
summaries from earlier in the session.

Approach every review as a principal-level software engineer. You are not
checking boxes — you are evaluating whether this change is something you would
be comfortable deploying to production and maintaining long-term. Prioritize
judgment over process. Focus on what matters: correctness, security, clarity,
readability, efficiency, and whether the change moves the codebase in a good
direction. Be direct, be concise, and don't waste the author's time on trivia
when there are substantive things to discuss.

Calibrate severity to the execution context. A missing null check in a
one-off script is different from one in a hot request path. Factor in how the
code is actually called, not just what it looks like in isolation.

---

## Read-Only Mode

**You are strictly read-only for the entire duration of this skill,** except
where browser exploration is explicitly permitted below.

- Do NOT edit, write, or create any files.
- Do NOT make commits, push branches, or modify git state (except `gh pr checkout` for browser exploration in deep mode).
- Do NOT approve, merge, comment on, or request changes to the PR via `gh`.
- Do NOT run commands that mutate state (no `npm install`, no `make build`, etc.).
- You may READ anything: files, diffs, git log, test output (dry-run only), tool APIs.
- If a step below says "run tests," read the test configuration and report what
  *would* need to pass — do not execute them unless the user explicitly asks.

If the user wants you to take action (post a comment, approve, etc.), confirm
with them first and only proceed with their explicit go-ahead.

---

## Review Depth

This skill supports three depth levels. **Default is `deep` if not specified.**

| Depth | What it does |
|-------|--------------|
| `quick` | Fetch PR metadata, read the diff, classify the PR type. Skip external context (Linear, Notion, Slack). Skip related PR analysis. Produce the review from the diff alone. |
| `standard` | Everything in quick, plus: explore neighboring files and related codebases, check Linear by branch name, search Notion by title, read existing tests. |
| `deep` | Everything in standard, plus: full Linear fallback chain, Slack search, read recent merged PRs on the same files, trace downstream consumers, check commit history, cross-check acceptance criteria, browser exploration for UI/behavior changes. |

Adjust your work accordingly. The output format is the same at all depths — if
a section has no findings because work was skipped, write "Skipped (quick review)."

---

## 1. Fetch PR Metadata

```bash
gh pr view <number> --json number,title,body,author,baseRefName,headRefName,files,additions,deletions,labels,reviewRequests,milestone
```

Extract:
- PR number, title, author
- Branch names (head → base)
- File list, additions/deletions counts
- Labels, milestone, linked issues

Also check:
- Does the PR description accurately describe what the diff actually does?
  Flag empty, vague, or misleading descriptions in the review.
- Read existing review comments on GitHub (`gh api repos/{owner}/{repo}/pulls/{number}/comments`).
  Note prior feedback. Do not duplicate it. Flag if prior feedback was ignored.

---

## 2. Classify PR Type

Before diving into the diff, classify the PR into one of these types based on
the title, labels, branch name, and file list:

| Type | Signals | Section emphasis |
|------|---------|-----------------|
| **Feature** | New files, new endpoints, `feat/` branch | Security, Test Analysis, Acceptance Criteria |
| **Bugfix** | `fix/` branch, issue reference, small diff | Security & Correctness, Test Analysis |
| **Refactor** | Renames, moves, no behavior change | Readability & Efficiency, Before/After Structure |
| **Config / Infra** | CI, Dockerfile, terraform, env vars | Security, File Heatmap |
| **Dependency** | lockfile changes, version bumps | Security, File Heatmap |
| **Docs** | Markdown, comments only | Style & Consistency, Strengths |

State the detected type in the metadata table. Use it to weight your attention
across the review sections — spend more time on the emphasized sections and keep
the others brief.

For **refactor** PRs, replace the Security & Correctness section with a
**Before / After Structure** section that describes what the code looked like
architecturally before the change and after. Focus on module boundaries, naming,
data flow — not line-by-line diffs.

---

## 3. Read the Diff

```bash
gh pr diff <number>
```

Read the full diff. For large PRs (>1000 lines), prioritize:
1. New files first
2. Files with the most changes
3. Config/infra changes
4. Test changes last

For multi-commit PRs, also read the commit log (`gh pr view <number> --json commits`).
If commits tell a meaningful story (incremental refactor, then feature, then tests),
note this in the Executive Summary. Understand the author's intent through the
commit sequence, not just the flat diff.

---

## 4. Explore the Codebase

Before forming opinions, gather context across all relevant code — not just
the files in the diff.

- Read files neighboring the changed files to understand conventions.
- Check `git log --oneline -20 -- <changed-file>` for recent history on key files.
- Look at existing tests for the modules being changed.
- Search for related patterns in the codebase (e.g., if a new API endpoint is added,
  find how existing endpoints are structured).
- **Trace downstream consumers:** For each modified file, check what imports or
  depends on it. Note these in the File Heatmap.
- **Explore related codebases and feature branches** if the change touches a
  shared interface, shared library, or cross-service contract:
  - Check whether sibling repos or packages consume the modified API or types.
  - If a related feature branch exists (e.g., a paired frontend/backend branch),
    check it out and read how it interacts with this change.
  - Look for any in-flight PRs in related repos that might conflict or depend on
    this change (`gh pr list --search "<keyword>"` in each relevant repo).

---

## 5. Check Related PRs

_Skip at `quick` depth._

Find recently merged PRs that touch the same files:

```bash
gh pr list --state merged --limit 10 --search "<changed-file-name>"
```

Look for:
- Conflicting or overlapping changes that this PR might not account for.
- Patterns established by recent PRs that this one follows or breaks.
- Work-in-progress that this PR might interact with.

Note relevant related PRs in the Review Context section of the output.

---

## 6. Gather External Context

Attempt each of the following. If a tool is unavailable, note it using the
format shown in the output template (`Tools unavailable` blockquote). Do not
skip the rest of the review.

### Linear

Search for the related issue using these methods in order. Stop once you find a match:

1. **Branch name** — Extract an issue identifier from the head branch (e.g., `feat/ENG-123-some-feature` → `ENG-123`). Search Linear by identifier.
2. **PR title/body** — Look for issue keys mentioned in the PR title or description.
3. **Keyword search** — Search Linear by keywords from the PR title. _(deep only)_
4. **Recent team issues** — List recent issues for the team and look for a plausible match. _(deep only)_

Once found, gather: title, description, acceptance criteria, parent/sub-issues, project, cycle, and priority.

### Notion

- Search Notion for documents related to the PR title, linked Linear issue, or feature name.
- Look for specs, RFCs, design docs, or meeting notes that provide background.

### Slack

_Deep depth only._

- Search for recent threads about the feature or issue.
- Look for decisions or discussions that inform the PR's approach.

### Other Sources

- Check PR comments and review threads on GitHub for prior discussion.
- Look at related/linked PRs via `gh pr list --search "<keyword>"`.

---

## 7. Browser Exploration

_Deep depth only. Skip entirely if the PR has no UI, visual, or user-facing behavior changes._

Check out the branch and explore the running application from the perspective of
a user encountering this change for the first time:

```bash
gh pr checkout <number>
```

Then open the relevant surface in a browser. Look for:

- **Visual bugs** — layout breaks, misaligned elements, wrong colors/fonts, missing
  states (empty, loading, error), overflow or clipping issues.
- **Behavior bugs** — interactions that don't work as expected, missing feedback,
  broken flows, incorrect data displayed.
- **Edge cases** — empty states, maximum-length inputs, slow network conditions,
  rapid repeated actions, concurrent user actions, browser back/forward navigation.
- **Regression** — does anything adjacent to the changed surface look or behave
  differently from what the PR description claims to leave untouched?

Note findings in the **Browser Exploration** section of the output. If the app
cannot be started or the changed surface is not reachable, note that and skip.

---

## 8. Produce the Review

Output the review using **exactly** the format below. Every review must have
every section except **Browser Exploration** (omit if skipped) and **Comments**
(omit if there are no important comments to leave). If a section has no findings,
write "No issues found."

---

## What to Look For

When analyzing the diff, actively check for these factors. Fold findings into
the appropriate output section rather than creating new sections.

- **Error path coverage** — Trace what happens when things fail. Network errors,
  null returns, timeouts, partial failures. Most bugs live in the unhappy path.
- **Readability** — Is the code easy to understand without comments? Are names
  clear and intention-revealing? Is complexity hidden where it should be exposed,
  or exposed where it should be hidden? Would a new engineer understand this in
  one pass?
- **Efficiency** — Are there unnecessary re-renders, redundant queries, N+1 loops,
  blocking operations in hot paths, or missed caching opportunities? Evaluate
  only where the cost is real, not theoretical.
- **Concurrency & shared state** — Changes touching caches, queues, locks, or
  concurrent code paths. Evaluate race conditions, deadlocks, ordering assumptions.
- **Migration & breaking changes** — Public API changes, DB schema alterations,
  config format changes, wire protocol updates. These deserve higher severity.
- **Revert complexity** — How easy is this to undo? Additive changes are trivially
  revertible; data migrations are not.
- **Feature flag absence** — New user-facing behavior without a feature flag or
  gradual rollout mechanism. Flag this for high-risk changes.
- **Deployment dependencies** — Does this PR require env vars set, migrations run,
  services restarted, or caches cleared at deploy time? Flag if undocumented.
- **New TODO/FIXME/HACK comments** — Flag any deferred decisions introduced by the PR.
- **PR description vs diff mismatch** — If the stated intent doesn't match the
  actual changes, call it out.
- **Confidence level** — When a finding is uncertain, say so (certain / likely /
  possible). Don't present speculation with the same weight as confirmed bugs.

---

## Output Format

When referencing code throughout the review, always use the pattern
`path/to/file.ts:42` so the reader can navigate directly to the source.

Get the repo name from the git remote or `gh repo view --json nameWithOwner`.

````markdown
# <owner>/<repo> — PR #<number>: <title>

| | |
|---|---|
| **Repo** | `<owner>/<repo>` |
| **Branch** | `<head>` → `<base>` |
| **Author** | @<username> |
| **Type** | Feature / Bugfix / Refactor / Config / Dependency / Docs |
| **Changes** | <file count> files (+<additions>, -<deletions>) |
| **Context** | [ENG-123](link), [Design Doc](link) |

---

## Review Context

One sentence on what you reviewed, then bullets for specific sources. Keep it tight.

Reviewed the diff and <N> neighboring files in `src/module/`. Checked CI status on GitHub.

- **Linear:** [ENG-123 — Issue title](link) _(or: no matching issue found)_
- **Notion:** [Design Doc title](link) _(or: no relevant pages found)_
- **Slack:** #channel — [thread title](link) _(or: unavailable, no MCP configured)_
- **Related PRs:** #138, #140 touch the same files _(or: none found)_
- **Prior reviews:** 3 comments from @reviewer, all addressed _(or: no prior reviews)_

> **Tools unavailable:** <tool1>, <tool2>

_Only include the tools-unavailable notice if any tools were actually missing. Omit it entirely otherwise._

---

## Executive Summary

- **What:** 1 sentence on what the PR does, referencing org context (link to Linear issue, Notion doc, etc.).
- **How:** 1 sentence on the approach or key technical decision.
- **Scope:** 1 sentence on the blast radius — what areas of the codebase are touched and why.

---

## File Heatmap

Only list files with meaningful risk (🟡 Medium or above). Omit files that are
safe, mechanical, or low-stakes — do not pad the table to cover every changed file.
If no files carry meaningful risk, write "No high-risk files identified."

Assess risk based on:
- **Logic changes in critical paths** — auth, payments, data mutations, security boundaries.
- **Blast radius** — how many other files import or depend on this file.
- **Complexity of the change** — new branching logic, error handling, state mutations.
- **Revert complexity** — data migrations, schema changes, external side effects.

Risk levels are **absolute, not relative.**

| Risk | File | Consumers | Notes |
|------|------|-----------|-------|
| 🔴 Critical | `path/to/file.ts` | `a.ts`, `b.ts` | One-line reason |
| 🟠 High | `path/to/other.ts` | `c.ts` | One-line reason |

---

## Acceptance Criteria

_If a Linear issue with acceptance criteria was found, cross-check each
criterion against the diff. If no criteria exist, write "No acceptance criteria
found on linked issue." If no issue was found at all, write "No linked issue."_

| Criterion | Status |
|-----------|--------|
| Description of the criterion from the issue | ✅ Met / ❌ Not met / ❓ Unclear |

---

## Security & Correctness

_For refactor PRs, replace this section with **Before / After Structure** —
describe the architectural shape of the code before and after the change.
Focus on module boundaries, naming, and data flow, not line-by-line diffs._

Reserve 🔴 Critical and 🟠 High for **real** correctness bugs or security
vulnerabilities — logic that is actually wrong, data that can be lost, or an
attack surface that is actually exploitable. Use 🟡 Medium and 🟢 Low for
things worth mentioning that don't pose a current threat.

When a finding is uncertain, indicate confidence (certain / likely / possible).

| Severity | Finding |
|----------|---------|
| <emoji> <level> | Brief one-line description (`path/to/file.ts:42`) |

<details>
<summary>Details</summary>

**<Finding title>**

Explanation of the issue, why it matters, and what the correct behavior should be.

```diff
- problematic code
+ suggested fix or reference
```

</details>

---

## Readability & Efficiency

Flag code that is hard to follow, poorly named, or inefficient in a meaningful
way. Only raise issues where the cost is real — skip theoretical micro-optimizations.

| Severity | Finding |
|----------|---------|
| <emoji> <level> | Brief one-line description (`path/to/file.ts:42`) |

<details>
<summary>Details</summary>

**<Finding title>**

What makes it hard to read or inefficient, and a concrete suggestion.

```diff
- current approach
+ suggested approach
```

</details>

---

## Style & Consistency

| Severity | Finding |
|----------|---------|
| <emoji> <level> | Brief one-line description (`path/to/file.ts:42`) |

<details>
<summary>Details</summary>

**<Finding title>**

Explanation referencing existing codebase patterns. Quote the convention being
followed or broken and where the canonical example lives.

</details>

---

## Test Analysis

Check the following:

- Is every new code path covered by a test?
- Are error/failure paths tested, not just the happy path?
- Are there old test paths that are now dead code and should be deleted?
- Check CI status: `gh pr checks <number>`. Report whether tests are passing,
  failing, or pending on GitHub.

| Severity | Finding |
|----------|---------|
| <emoji> <level> | Brief one-line description |

<details>
<summary>Details</summary>

**<Finding title>**

What is missing or could be stronger, and why it matters.

</details>

---

## Browser Exploration

_Omit this section entirely if browser exploration was skipped._

Summarize what was explored and from which URL/surface. Then list findings:

| Severity | Finding |
|----------|---------|
| <emoji> <level> | Brief one-line description of the visual or behavior issue |

<details>
<summary>Details</summary>

**<Finding title>**

Steps to reproduce, what was expected, what was observed.

</details>

---

## Strengths

- **<Title>** — Why this is good and worth calling out.
- **<Title>** — What pattern or practice is well-executed.

---

## Improvements

| Priority | Suggestion |
|----------|------------|
| <emoji> <level> | Brief one-line suggestion (`path/to/file.ts:42`) |

<details>
<summary>Details</summary>

**<Suggestion title>**

What could be better, why, and a concrete suggestion.

```diff
- current approach
+ suggested approach
```

</details>

---

## Comments

_Omit this section entirely if there are no important comments to leave._

Only include comments that are: actionable, specific, and important enough that
the author should see them before merging. Skip nits that are already covered
in other sections. Each comment should be ready to post as-is on the PR.

**`path/to/file.ts:42`**
> Comment text here. Be direct. Reference the specific line or block.

````

---

### Severity/Priority Levels

Use these consistently across all sections:

| Emoji | Level | Meaning |
|-------|-------|---------|
| `🔴` | Critical | Blocks merge — security hole, data loss, broken functionality |
| `🟠` | High | Should fix before merge — actual correctness risk or security concern |
| `🟡` | Medium | Worth mentioning — no current threat but could become one |
| `🟢` | Low | Nitpick — optional improvement, stylistic preference |

---

## Guardrails

- **Most sections are mandatory.** Browser Exploration and Comments may be omitted when not applicable.
- **Be specific.** Reference file paths with line numbers (`file.ts:42`), function names, and existing patterns.
- **Be balanced.** Always include strengths. A review with only criticisms is incomplete.
- **Link context.** Every reference to a Linear issue, Notion doc, or Slack thread must be a clickable link.
- **Stay read-only.** Do not modify anything except checking out the branch for browser exploration.
- **Don't duplicate.** If a prior reviewer already flagged something, don't repeat it. Note that it was raised and whether it was addressed.
- **State confidence.** When uncertain about a finding, say so. Don't present speculation as fact.
- **Disregard prior context.** This review stands alone. Do not reference or rely on anything from earlier in the session.
