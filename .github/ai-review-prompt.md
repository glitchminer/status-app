# AI review checklist (status-app)

Report at most 8 findings, ordered by severity. For each: `file:line`, what is wrong, the concrete input or state that triggers it, and a fix. Skip style unless `AGENTS.md` or the Qt skills in `.github/skills/` name it.

Severity, one per finding:
- **Blocker**: wrong behaviour users or CI will hit, data loss, a security gap, or a test that cannot pass.
- **Should fix**: a real defect in a less common path, or a missing check that hides one.
- **Minor**: everything else worth saying (conventions, small clarity issues). Never posted inline. A finding with a concrete input that gives a wrong result is never Minor, however rare the input: Minor findings are folded away and devs may not open them.

Write in plain, short English: many readers use English as a second language. No praise, no restating the diff.

Before writing anything, for each changed function or QML component list the inputs and states it must handle, including pending or stale async state, partial failures and platform differences, and check the diff against each. A concrete input that produces wrong behaviour is a defect: report it at its real severity even if the input is uncommon.

1. **Correctness.** Logic errors, nil/undefined handling in Nim and QML bindings, signal/slot wiring, async ordering, resource leaks, Qt object ownership and lifetime (see `.github/skills/qt-qml-review` and `qt-cpp-review`).
2. **Layer ownership.** Is the fix at the layer that owns the behaviour (QML/StatusQ → Nim `src/` → `vendor/status-go`)? Flag UI- or Nim-side workarounds for backend problems.
3. **AGENTS.md compliance.** Branching from the latest `master` of `status-im/status-app`, Conventional Commit subject (the team also uses `tests` as a type; accept it), `Assisted-by:` trailer when the PR or a commit says an AI tool helped (never `Co-authored-by:` for a tool), no hand edits to vendored or generated code. Do not report the `vendor/status-go` pointer: CI checks it.
4. **Traceability (tests only).** Appium tests under `test/e2e_appium/` that implement a spec scenario carry `@pytest.mark.spec("SC-XXX-NN")`. Flag a marker removed or changed by the diff, and a new test for a scenario that clearly has one but no marker. Do not invent IDs.
5. **Owner-review triggers.** Any change outside `test/` and `storybook/` touching wallet signing, keystore, keycard, permissions, or token transfer starts the verdict with `Touches wallet/keycard/permissions code: request review from the owners in CODEOWNERS.`
6. **Tests.** Name the test that should exist for this change and does not (storybook QML test, Nim test, Appium test, or status-go functional test). If tests were added, say whether they would fail without the change. For Appium changes, check page-object rules: no direct driver calls in tests, no `time.sleep`.
7. **PR hygiene.** Suggest a split only when the diff is over 400 changed lines and mixes unrelated concerns. Do not report empty template sections.
8. If nothing of substance is wrong, return no findings and say so in the verdict.

Output:
- Return the review as structured output: `verdict` (one sentence a dev can act on, e.g. "Not ready: the send-modal network check can never pass."), `findings`, and `tests` (tests to add, one short line each).
- Each finding: `severity`, `location` (`path:line`), `title` (one sentence, at most 20 words), and `detail` (scenario and fix, at most 60 words).
- For each Blocker or Should fix on a changed line, also post one inline comment: first line `**<severity>:** <title>`, then the detail. At most 60 words. Set `inline` to true for those findings.
