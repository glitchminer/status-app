# AGENTS.md — status-app

Instructions for AI coding agents working in this repository. `CLAUDE.md` imports this file and `.github/copilot-instructions.md` points to it, so every tool reads the same rules. Nested `AGENTS.md` files (for example `test/e2e_appium/AGENTS.md`) override this one for their directory.

## What this repo is

The Status app: desktop and mobile, one codebase. QML/StatusQ frontend (`ui/`), Nim middleware (`src/`), local Go backend in `vendor/status-go` (git submodule). Local-first: there is no application server; the backend runs on the device and user data lives in local databases. On Android, status-go can run as a separate local service with a stub layer — read `docs/adr/` before touching mobile service, IPC, login-resume or notification flows.

Read `docs/architecture.md` and `guidelines/QML_ARCHITECTURE_GUIDE.md` before changing structure.

## Fix things at the layer that owns them

- Presentation and interaction → QML / StatusQ.
- App orchestration, signals, module wiring → Nim in `src/`.
- Backend logic, persistence, protocol, notifications → `vendor/status-go`. If the root cause is there, change it there and open the status-go PR; do not add a UI- or Nim-side workaround.
- When a change spans layers, trace the full path (QML → Nim → status-go) before editing.

## Build and test

Setup is in `BUILDING.md` (desktop) and `mobile/DEV_SETUP.md` (mobile). Do not re-derive it; link to it.

| Task | Command |
| --- | --- |
| Desktop build | `make` (`make nim_status_client`) |
| Run desktop | `make run` |
| Mobile build / run | `make mobile-build` / `make mobile-run` (platform follows the Qt kit on `PATH`; see `mobile/DEV_SETUP.md`) |
| QML lint | `make qml-lint` (desktop), `make qml-lint-mobile` |
| StatusQ unit tests | `make run-statusq-tests` |
| Storybook QML tests | `make run-storybook-tests`; one test: `make storybook-build` then `ctest --test-dir storybook/build/Qt<version> -R <TestName>` (tests in `storybook/qmlTests/tests/`) |
| Nim tests | `make tests-nim` (`test/nim/`) |
| Desktop e2e (Squish) | `test/e2e/`, see its README; needs a Squish licence |
| Mobile e2e (Appium) | `test/e2e_appium/`, see its `AGENTS.md`; BrowserStack or local Appium |
| status-go functional tests | in the `status-go` repo, `tests-functional/` (not from the submodule) |

Run the narrowest check that covers the change before claiming it works. A QML-only change needs `qml-lint` and the relevant storybook test, not a full desktop build.

## Branches, commits, PRs

- Branch from the latest `master` of `status-im/status-app` (desktop and mobile are one repo). Release branches are `release/**`.
- Conventional Commits: `<type>(scope): <description>`. Example: `fix(wallet): handle empty token list on startup`.
- If an AI tool helped, add one trailer: `Assisted-by: <tool>`. Never `Co-authored-by:` for a tool. The human stays sole author; do not change author or committer identity.
- Commit signing is recommended practice in the org. If you cannot sign, leave the commit to the human.
- PRs use `.github/pull_request_template.md`: what, affected areas, how to test, impact. One concern per PR; keep it readable by a human reviewer.
- `vendor/status-go` must point at a commit on a status-go `develop`-derived branch; CI (`pr.yml`) checks this.

## Testing and traceability

- Appium tests under `test/e2e_appium/` that implement a specification scenario carry `@pytest.mark.spec("SC-XXX-NN")`. Keep existing markers when editing a test; do not invent IDs (specs live in `status-docs`).
- Appium framework rules (page objects, locators, no `time.sleep`): `.cursor/rules/appium-framework-standards.mdc` and `test/e2e_appium/AGENTS.md`.

## Do not

- Hand-edit generated or vendored code (`vendor/`, generated resources). Change the source.
- Change wallet signing, keystore, keycard, or permissions code without saying so in the PR description and requesting review from the owners of that code (`.github/CODEOWNERS`).
- Add dependencies without updating `BUILDING.md` / `mobile/DEV_SETUP.md`.
- Describe or implement features as if a hosted server exists.

## Where the rest lives

- Qt and QML review skills: `.github/skills/` (qt-qml, qt-qml-review, qt-cpp-review, qt-ui-design).
- Editor rules: `.cursor/rules/`.
- Architecture decisions: `docs/adr/`. Quality attributes: `docs/FURPS/`.
- Copilot-specific notes: `.github/copilot-instructions.md`.
