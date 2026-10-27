# AI review checklist (status-app)

Report at most 8 findings, ordered by severity. For each: `file:line`, what is wrong, why it matters, a concrete fix. Skip style unless `AGENTS.md` or the Qt skills in `.github/skills/` name it.

1. **Correctness.** Logic errors, nil/undefined handling in Nim and QML bindings, signal/slot wiring, async ordering, resource leaks, Qt object ownership and lifetime (see `.github/skills/qt-qml-review` and `qt-cpp-review`).
2. **Layer ownership.** Is the fix at the layer that owns the behaviour (QML/StatusQ → Nim `src/` → `vendor/status-go`)? Flag UI- or Nim-side workarounds for backend problems.
3. **AGENTS.md compliance.** Branching from `upstream/master`, Conventional Commit subject, `Assisted-by:` trailer where an AI tool helped (never `Co-authored-by:` for a tool), no hand edits to vendored or generated code, `vendor/status-go` pointing at a `develop`-derived commit.
4. **Traceability (tests only).** Appium tests under `test/e2e_appium/` that implement a spec scenario carry `@pytest.mark.spec("SC-XXX-NN")`. Flag a marker removed or changed by the diff, and a new test for a scenario that clearly has one but no marker. Do not invent IDs.
5. **Owner-review triggers.** Any change touching wallet signing, keystore, keycard, permissions, or token transfer gets a one-line `Touches wallet/keycard/permissions code — request review from the owners in CODEOWNERS` flag at the top of the summary.
6. **Tests.** Name the test that should exist for this change and does not (storybook QML test, Nim test, Appium test, or status-go functional test). If tests were added, say whether they would fail without the change. For Appium changes, check page-object rules: no direct driver calls in tests, no `time.sleep`.
7. **PR hygiene.** More than one concern in the diff → suggest a split. PR template sections (what, affected areas, how to test, impact) empty → say which.
8. If nothing of substance is wrong, say so in two sentences and stop.

Summary format:

```
## AI review

<one line: overall verdict, or the readiness-review flag>

### Findings
1. `path:line` — <what> — <why> — <fix>
...

### Tests to add
- ...
```
