---
name: pr-review
description: Review a GitHub pull request with repository architecture, stack context, existing review threads, branch freshness, CI evidence, affected consumers, and applicable repository instructions. Use when asked to review a PR, given a PR URL or number, or asked for a quick, standard, or deep local review before merge.
---

# PR Review

Review for actionable correctness, security, compatibility, and maintainability risks. Use architecture artifacts to route investigation, then verify material claims against the PR's actual base and head.

## Operating rules

- Remain read-only unless the user explicitly asks for another action. Do not edit files, checkout branches, create worktrees, install dependencies, comment, approve, merge, or push.
- Preserve relevant user-provided requirements and constraints. Treat summaries and architecture artifacts as leads, not proof.
- Prefer the diff, current source, applicable instructions, CI output, and concrete call paths over speculation.
- Do not duplicate an existing unresolved review comment.
- Do not manufacture findings to fill a template. A clean review may have no findings.
- Default to `standard` depth.

| Depth | Scope |
|---|---|
| `quick` | PR state, full diff, existing feedback, available architecture, and obvious correctness risks. |
| `standard` | Quick plus path-scoped instructions, callers and consumers, stack context, tests, contracts, and deployment impact. |
| `deep` | Standard plus relevant history, cross-repo verification, linked product context, and user-authorized runtime or browser validation. |

## 1. Resolve the review target

Identify the repository and PR. If no number is given, use the PR associated with the current branch when unambiguous.

Collect metadata without checking out the branch:

```bash
gh repo view --json nameWithOwner
gh pr view <pr> --json number,url,title,body,author,baseRefName,baseRefOid,headRefName,headRefOid,isDraft,mergeStateStatus,reviewDecision,files,changedFiles,additions,deletions,commits,comments,latestReviews,reviewRequests,statusCheckRollup,closingIssuesReferences
gh pr diff <pr>
```

For large PRs, still account for every changed file. Start with public contracts, schemas, migrations, auth, stateful code, new files, and high-fanout modules; then inspect the remaining files.

Check that the description matches the actual change. Understand meaningful commit sequencing, but judge the final diff.

## 2. Run the PR preflight

Collect these dimensions separately rather than collapsing them into one merge state:

### Existing feedback

- Read issue comments, submitted reviews, and review threads.
- Use GitHub GraphQL `reviewThreads` so `isResolved` and `isOutdated` are visible; paginate when needed.
- For each unresolved thread, retain its path, line, latest comment, author, and URL.
- Do not repeat an existing concern. Note whether the new diff addresses or invalidates it.

### CI and branch freshness

- Read check runs and commit statuses for the head SHA.
- For failed checks, read failure annotations or the narrow failing job logs before drawing conclusions.
- Compare the base SHA to the head SHA and record `ahead_by`, `behind_by`, and conflict/mergeability state.
- Report pending, failing, action-required, and passing checks distinctly.

### Stack context

List open PRs in the repository with their base and head branch names:

```bash
gh pr list --state open --limit 200 --json number,title,url,baseRefName,headRefName
```

- The parent is an open PR whose head branch equals this PR's base branch.
- Children are open PRs whose base branch equals this PR's head branch.
- Review this PR against its immediate base. Note contracts or behavior that affect a parent or child.

## 3. Load architecture context

Locate `refresh-repo-architecture/scripts/architecture.py` under the same shared skill root. If it is available, run a targeted scan using the current repository's workspace parent or `$WORKSPACE_ROOT`:

```bash
python3 <architecture.py> scan --root <workspace-root> --repo <owner/name> --pretty
```

Handle the result as follows:

- `fresh`: read the repository `ARCHITECTURE.md` and only component artifacts whose `scope` contains a changed path.
- `stale`: use the artifact as orientation only. Inspect `changed_paths` since its source SHA and verify every affected claim at the PR base.
- `divergent`, `invalid`, or `missing`: do not rely on the artifact. Build the required context directly from source and mention the limitation.
- Do not refresh or rewrite architecture state during a read-only review unless the user separately asked for it.

Independently compare the artifact's `source_sha` with the PR `baseRefOid`. A `fresh` artifact is fresh for the repository's default ref, not necessarily for a stacked or older PR base. If the SHAs differ, inspect the commits and paths between them. Use the artifact only as orientation when its source is not an ancestor of the PR base; verify the base architecture directly.

Read the applicable `AGENTS.md` and `CLAUDE.md` hierarchy for every changed area. If an instruction file changes in the PR, compare its base and head versions.

Use architecture to identify likely boundaries, contracts, persisted state, and sibling repositories. Confirm actual imports, callers, API usage, schema usage, or deployment wiring before treating a consumer as affected.

## 4. Build the impact map

For each meaningful changed area, determine:

- The entrypoint or caller that reaches it.
- State read or mutated, including failure and retry behavior.
- Direct callers and downstream consumers.
- Public API, event, schema, migration, configuration, or file-format changes.
- Cross-repository consumers supported by evidence.
- Deployment ordering, rollout, rollback, or compatibility requirements.
- Tests that protect the affected invariant rather than merely execute the new line.

For a refactor, compare the before and after boundaries and data flow. Verify behavior did not change accidentally.

## 5. Review the risky paths

Prioritize concrete execution risks:

- Incorrect success, error, timeout, cancellation, retry, or partial-failure behavior.
- Authorization, trust-boundary, secret, injection, and sensitive-data exposure issues.
- Races, stale reads, lost updates, ordering assumptions, cache invalidation, and non-idempotent retries.
- Backward-incompatible APIs, schemas, events, migrations, or configuration.
- Deployment sequencing and irreversible data changes.
- Broken callers, consumers, feature branches, or stack children.
- Missing tests only when an unprotected behavior could realistically regress.
- Meaningful hot-path or resource regressions supported by the execution context.

Use linked Linear or Notion material when the PR or branch explicitly references it, or when requirements cannot otherwise be established. Search Slack only at `deep` depth when discussion is likely to contain a necessary decision. Missing external tools must not block the code review.

## 6. Apply the finding bar

Before reporting a finding, establish all of the following:

1. The changed code or assumption that introduces it.
2. A reachable execution path or affected consumer.
3. A concrete incorrect or harmful outcome.
4. Source, CI, contract, or history evidence.
5. An actionable correction or expected behavior.

If one is missing, investigate further or present it as an open question. Do not report generic style preferences, hypothetical scaling concerns, or blanket requests for more tests.

Use severity consistently:

| Priority | Meaning |
|---|---|
| `P0` | Immediate security compromise, widespread outage, or irreversible data loss. |
| `P1` | Merge-blocking correctness, security, or compatibility defect. |
| `P2` | Real but bounded defect that should be fixed. |
| `P3` | Low-impact improvement; omit unless it materially helps the author. |

State confidence when evidence is incomplete. Use exact `path/to/file:line` locations from the head diff.

## 7. Validation policy

- Read CI results by default; do not claim local tests ran when they did not.
- Run local tests, builds, or browsers only when the user explicitly requests validation. Read repository instructions first and choose the narrowest relevant command.
- Never use `gh pr checkout` for a read-only review.
- If runtime validation is unavailable, name the unverified behavior and resulting residual risk.

## Output

Lead with findings. Omit empty optional sections.

```markdown
# <owner/repo> PR #<number> — <title>

## Findings

### [P1] <Actionable title> — `path/to/file.ts:42`

<Trigger and execution path. Concrete outcome. Supporting evidence. Expected behavior or correction. Confidence if needed.>

## Open questions

- <Only unresolved questions that could change the review.>

## Architecture impact

<Changed boundaries, contracts, persisted state, consumers, stack effects, and deployment implications. Say "No material architecture change" when appropriate.>

## Validation

- Architecture: <fresh SHA / stale and live-verified / unavailable>
- Existing feedback: <unresolved and addressed summary>
- CI: <passing, failing, pending, or unavailable>
- Local validation: <not run, or exact commands and results>

## Summary

<Two or three sentences on intent, approach, and residual risk.>
```

If there are no findings, write `No actionable findings.` under `## Findings`. Do not add praise or filler. Draft ready-to-post comments only when the user asks; never post them without explicit authorization.
