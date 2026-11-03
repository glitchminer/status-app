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

Setup is in `BUILDING.md` (desktop) and `mobile/README.md` / `mobile/DEV_SETUP.md` (mobile). Do not re-derive it; link to it. After dependencies are installed: `make update` then `make run`.

| Area | Run | Run one test |
| --- | --- | --- |
| Nim host tests (`test/nim/`) | `make tests-nim` | `make nim-test-run/test/nim/<test_file>.nim` |
| StatusQ C++ tests | `make run-statusq-tests` | `make run-statusq-tests ARGS="-R <CTestName>"` |
| Storybook QML tests (`storybook/qmlTests/tests/`) | `make run-storybook-tests` | Run the built `QmlTests` executable with `<TestCase>::<test_function>`, or pick the test in Qt Creator |
| QML lint | `make qml-lint` (desktop), `make qml-lint-mobile` | whole `ui/` tree only |
| Desktop e2e (Squish, `test/e2e/`) | from `test/e2e` with its venv: `pytest -m critical` | `pytest tests/<path>::<test> -v` |
| Mobile e2e (Appium, `test/e2e_appium/`) | see `test/e2e_appium/AGENTS.md` | `python -m pytest tests/<path> -v --env=local` |
| Mobile build / run | `make mobile-build` / `make mobile-run` (platform follows the Qt kit on `PATH`) | — |
| status-go functional tests | in the `status-go` repo, `tests-functional/` (not from the submodule) | — |

`_bench.nim` files are benchmarks, not tests. Run the narrowest check that covers the change before claiming it works: a QML-only change needs `qml-lint` and the relevant storybook test, not a full desktop build.

## Conventions that CI or reviewers enforce

- Nim modules follow view / interface / module / controller; interfaces connect view and controller, controllers call services (`docs/architecture.md`).
- QML: backend access goes through domain stores; model and data transformations live in adaptors, not views or stores; popups go through the app-level popup handlers (`guidelines/QML_ARCHITECTURE_GUIDE.md`). `ui/StatusQ` is the reusable component library; `AppLayouts` must not become a StatusQ dependency.
- All user-visible QML text is wrapped in `qsTr("...")` (`qsTr("%n item(s)", "", count)` for plurals). After adding or changing strings, run `make update-translations` and commit `ui/i18n/qml_base.ts` and `ui/i18n/qml_en.ts`; CI enforces this (`I18N.md`).
- New QML unit tests go in `storybook/qmlTests/tests/` (run without the backend, using stubs); StatusQ-specific tests may live under `ui/StatusQ/tests`.

## Branches, commits, PRs

- Branch from the latest `master` of `status-im/status-app` (desktop and mobile are one repo). Release branches are `release/**`.
- Conventional Commits: `<type>(scope): <description>`. Example: `fix(wallet): handle empty token list on startup`.
- If an AI tool helped, add one trailer: `Assisted-by: <tool>`. Never `Co-authored-by:` for a tool. The human stays sole author; do not change author or committer identity.
- Commit signing is recommended practice in the org. If you cannot sign, leave the commit to the human.
- PRs use `.github/pull_request_template.md`: what, affected areas, how to test, impact. One concern per PR; keep it readable by a human reviewer.
- `vendor/status-go` must point at a commit on a status-go `develop`-derived branch; CI (`pr.yml`) checks this.

## Testing and traceability

- Appium tests under `test/e2e_appium/` that implement a specification scenario carry `@pytest.mark.spec("SC-XXX-NN")`. Keep existing markers when editing a test; do not invent IDs (specs live in `status-docs`).
- Appium framework rules (page objects, locators, no `time.sleep`, `ruff`): `test/e2e_appium/AGENTS.md`.

## Do not

- Hand-edit generated or vendored code (`vendor/`, generated resources). Change the source.
- Change wallet signing, keystore, keycard, or permissions code without saying so in the PR description and requesting review from the owners of that code (`.github/CODEOWNERS`).
- Add dependencies without updating `BUILDING.md` / `mobile/DEV_SETUP.md`.
- Describe or implement features as if a hosted server exists.

## Where the rest lives

- Qt and QML review skills: `.github/skills/` (qt-qml, qt-qml-review, qt-cpp-review, qt-ui-design).
- Architecture decisions: `docs/adr/`. Quality attributes: `docs/FURPS/`.
- Copilot's copy of these rules: `.github/copilot-instructions.md` (keep in agreement with this file).
