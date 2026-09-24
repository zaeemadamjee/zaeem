---
name: better-tests
description: "Gate every new test behind a named break and a cost check, hold survivors to behavior-only quality rules, and spawn Test Sicko to hunt worthless tests in a diff. Use when writing tests, reviewing tests, or deciding whether a change needs one."
---

# Better tests

A test earns its place or it does not exist. Omitting a test is a valid outcome, stated with its reason, never a silent lapse and never a checkbox ticked with a bad test. Prefer no test over a bad test.

## The gate

Run these four questions, in order, before writing any test. Failing one ends the attempt; report "no test: <reason>".

1. **Name the break.** Name the specific production *bug* that would make this test fail. If you cannot, or if only an intentional *decision* could fail it (a constant, exact copy or wording, styling and CSS, private structure, a snapshot of current output), it is a change detector and provides negative value. A CSS fix, copy tweak, or visual change is a decision a human judges on the rendered surface; it earns runtime verification, not a test.
2. **Worth its cost?** Weigh the test's write-and-maintain cost against what breaks and who it hurts. Earns a test: logic and branching, parsers and serializers, boundary contracts you emit or consume (the query, the payload, the route), error paths, anything touching money, auth, or data loss. Does not: trivial glue and forwarding, getters, config, generated code, one-off scripts, framework mechanics (the framework's maintainers test that a registered handler is invoked), prose.
3. **Already covered?** Each contract has one primary test at the strongest boundary that can reach it. Another layer earns a test only for a risk the owner cannot reach, such as a transport or lifecycle failure. Extend the existing table-driven case or fixture instead of adding a near-duplicate.
4. **Bug fix?** A defect with a cheap local repro gets a regression test, failing before the fix for the intended reason, via the **tdd** skill. One regression at the owning boundary covers the bug; do not replay it at every layer it crosses. When the repro is expensive relative to the bug, skip the test, verify on the real surface, and say so.

## Quality rules

For tests that clear the gate.

- **Behavior through the public API.** No internal state, private methods, or call-sequence assertions. A refactor that preserves behavior must not break the test; if it would, the test encodes implementation, rewrite it.
- **No test-only seams.** If the test needs an export, flag, wrapper, or injection hook that no production caller uses, move the test to the real boundary. Production code whose only callers are tests is dead; delete it with the test.
- **Real collaborators by default.** Mock only what is slow, external, or nondeterministic: network, clock, payments, email. Needing to mock everything is a design smell in the code under test; fix the coupling, not the mocks.
- **Never assert on a mock.** If deleting the mock is what makes the assertion fail, the test verifies the mock. Assert on the code's observable output instead, or delete the test. The same goes for a mock or fixture that performs the behavior under test: one that supplies the ordering, ID, or callback the code should produce, or one generic mock standing in for several different APIs.
- **Don't mock what you don't own.** Wrap a third-party dependency in a thin adapter and mock the adapter. Exception: simulating failures that are hard to produce for real (timeouts, network faults).
- **Promote when mocks outgrow logic.** Mock setup larger than the test body means the unit boundary is wrong; write an integration test with real components instead. Integration tests buy the most confidence per cost.
- **Derive expected values by hand.** Literals and hand-checked fixtures. An expectation computed by the code under test, or its helpers, always passes and proves nothing.
- **DAMP over DRY.** Tests have no tests, so they must be obviously correct by inspection: inline setup, visible literals, no loops or helpers that hide expected values. Helpers only for value-object plumbing irrelevant to the assertion.
- **One behavior per test, named for the behavior.** An "and" in the name means split it. The name promises no more than the input exercises: a "clears the cache" test must observe the cache cleared. Assertion messages carry the doc; no narrating comments (the **no-comments** skill).
- **Watch it fail for the right reason.** A test never seen red is unproven. Run it against broken or pre-fix code, or mutate the code to check it can fail. A negative test must fail at the guard it names; a rejection from a different guard, or one the production path never reaches, proves nothing.
- **The mutation check.** Before finishing, mentally flip a constant, invert a branch, drop a side effect in the code under test. Each realistic mutation must fail at least one test, or the behavior is unprotected and the suite is decorative.
- **Coverage is a diagnostic, never a target.** Never add a test solely to hit a line or a percentage. The lines only reachable through implementation details are the gate telling you no.

## Review mode

For an existing diff or test suite, spawn a subagent with the persona prompt in `references/test-sicko.md`, passed verbatim, plus the scope (the caller's files or diff; otherwise the current diff against the base branch, default `main`, including the working tree). Without subagent support, adopt the persona yourself for a dedicated pass and produce the same report.

Inspect its report. Test Sicko flags; you decide. Before accepting a deletion, read the whole test, the production code it covers, that code's callers, and overlapping tests, and name the stronger test that still protects the behavior (or why none is needed). Reject flags whose named break is wrong, and flags on tests that pin a real contract even when they look mock-heavy, static, or slow: a public API, wire protocol, config or storage format, migration, security rule, or call order that callers observe. A kept test that fails on the base branch may be a product bug; reproduce it before touching the test. Accept deletions of change detectors, tautologies, and mock-verifying tests without replacing them; their value is negative, removal is the fix. Delete the test-only exports and dead code they kept alive in the same change. Never delete an uncertain test to pad the count. A flagged test guarding real behavior badly gets rewritten under the quality rules, not deleted.

Report tests deleted, rewritten, kept over a flag with the reason, production code removed, and gaps where behavior worth testing has no test.
