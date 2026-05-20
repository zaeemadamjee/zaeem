---
name: write-pr-description
description: >
  Generate a high-quality pull request description from the current branch.
  Gathers context from the git diff, commit log, Linear, Notion, and Slack, then
  produces a complete PR description. Use when asked to write, draft, or generate
  a PR description, or when the user says "write the PR description" or "describe this PR".
---

# Write PR Description

Generate a PR description for the current branch. Produce text only — do not
run `gh pr create`. Present the result in a markdown code block so the user can
copy it directly.

---

## 1. Read the branch

```bash
git rev-parse --abbrev-ref HEAD          # current branch name
git log main...HEAD --oneline            # commits on this branch
git diff main...HEAD                     # full diff vs base
```

Extract:
- Linear issue key from branch name (e.g. `feat/ENG-123-add-login` → `ENG-123`)
  or from commit messages if not in branch name
- App name: check `package.json` → `name`, or infer from `gh repo view --json name`
- A plain-English summary of what changed

For large diffs (>500 lines), prioritize: new files, most-changed files, config changes.

---

## 2. Gather external context

Attempt each source. Skip silently if unavailable.

**Linear** — search by issue key first, then commit keywords. Gather: title, description, acceptance criteria.

**Notion** — search for specs or design docs related to the Linear issue or feature name.

**Slack** — search for threads about the feature or issue key. Look for decisions that explain the approach.

---

## 3. Check for a repo PR template

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
  || cat .github/pull_request_template.md 2>/dev/null
```

If a template exists, fill it in. If not, use the structure below.

---

## 4. Description structure

### Title

Format: `[app-name]-[LINEAR-TICKET] - 3-7 word imperative description`

Examples:
- `[studio]-WEB-123 - Fix checkout crash on empty cart`
- `[jerboa]-ENG-456 - Add rate limiting to auth endpoints`

Keep the description to 3–7 words. No trailing punctuation.

---

### Summary

Two to four sentences max. Write for a non-technical reader.

1. Context — what part of the product/system does this touch?
2. Problem — what was wrong or missing?
3. Solution — what does this PR do about it?

Do not describe implementation details here. Link the Linear issue inline if found
(e.g. `Closes ENG-123`). Link a Notion doc if one was found and adds useful context.

---

### Important Changes

Group changes into meaningful categories rather than listing every file. Use judgment:

| Prefer this category... | ...over listing files like |
|-------------------------|---------------------------|
| API / Backend | `src/api/auth.ts`, `src/api/user.ts` |
| UI / Frontend | `components/Button.tsx`, `pages/login.tsx` |
| Database / Migrations | `migrations/0042_add_index.sql` |
| Config / Infra | `docker-compose.yml`, `.env.example` |
| Tests | `__tests__/auth.test.ts` |

If changes don't fit a category, group by file. Use bullets. One line per item, brief.

```markdown
**API / Backend**
- Added rate limiting middleware to `/auth/*` routes
- Extended `UserService.findById` to return role permissions

**UI / Frontend**
- New `<RateLimitBanner>` component shown on 429 response
- Login page disables submit button while request is in-flight
```

---

### Screenshots _(include only if screenshots are available in this conversation)_

If the user has shared screenshots, or screenshots exist in the diff/assets, include
a before/after table:

```markdown
| Before | After |
|--------|-------|
| ![before](url) | ![after](url) |
```

**Omit this section entirely** if no screenshots are available. Do not add a
placeholder or ask the user for screenshots.

---

### Testing _(include only if testing or reproducing is non-obvious)_

Include this section only when:
- Reproducing the bug requires specific steps or data setup
- Testing the feature requires a non-trivial environment or config
- There are edge cases a reviewer should specifically verify

If testing is straightforward (run the test suite, click the button), omit this
section entirely. Do not add a generic "run `npm test`" note.

When included, write concise steps:

```markdown
**To reproduce the original bug:**
1. Add 3+ items to cart, remove all
2. Click "Checkout" — previously crashed

**To verify the fix:**
1. Repeat steps above — should redirect to empty cart page
```

---

## 5. Output format

```
**Title:** mirage-ENG-123 - Fix checkout crash on empty cart

**Description:**
[full markdown here]
```

If the app name or Linear ticket can't be determined, note it so the user can fill in the title manually.
