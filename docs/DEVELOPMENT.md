# Development guide

How this repo is built, tested and changed. Read it together with [ARCHITECTURE.md](ARCHITECTURE.md) and [UI_GUIDELINES.md](UI_GUIDELINES.md).

## Setup
- Xcode 27.1 for development; the code must also build on Xcode 26.0.1.
- `brew install swiftlint swiftformat`, needed only for linting. Building and running the app needs nothing beyond Xcode.
- The Apollo codegen CLI, needed only to change GraphQL operations ([Codegen](#codegen)).

## Commands
| Task | Command |
|---|---|
| Build and run | open `CountriesApp.xcodeproj`, then ⌘R |
| All tests | `xcodebuild test -scheme CountriesApp -testPlan CountriesApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0'` |
| Package tests on macOS | `swift test --package-path Packages/CountriesData` (also `CountriesDomain`) |
| Lint | `scripts/lint.sh` |
| Format, then lint | `scripts/lint.sh --fix` |
| Test matrix | `scripts/test-matrix.sh` |
| Record snapshots | see [Snapshot tests](#snapshot-tests) |
| Codegen | see [Codegen](#codegen) |

## Rules
- **Layers:** `UI → Domain ← Data`; no layer is skipped. Apollo and generated types never leave CountriesData.
- **Zero warnings.** Every warning in our code is a build error: `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `Config/Shared.xcconfig` for the app, `.treatAllWarnings(as: .error)` in each `Package.swift`. Don't pass `SWIFT_TREAT_WARNINGS_AS_ERRORS` on the `xcodebuild` command line: it also reaches Apollo, whose warnings Xcode suppresses, and the two flags conflict.
- **Xcode 26.0.1 is the floor** (Swift 6.2, iOS 26 SDK): no Swift features newer than 6.2, and no iOS 27 SDK APIs, even behind `#available`. iOS 18 and iOS 26 APIs need an `#available` check with an iOS 17 fallback. The project file stays in the "Xcode 16.0" format (`objectVersion = 77` in `project.pbxproj`; Project → File inspector → Project Format), because Xcode 26.0.1 knows no format newer than "Xcode 16.3". Check it after every project-file change.
- **Concurrency:** async/await everywhere. Combine only in the search input pipe.
- **Logging:** `os.Logger`, never `print`.
- **UI:** every user-facing string goes through the String Catalog with `bundle: .module`, layouts use leading/trailing only, and every UI change ships snapshot tests ([UI guidelines](UI_GUIDELINES.md)).
- **Dependencies:** Apollo iOS is the only third-party library, pinned to an exact version. Tests use no third-party packages.

## Story workflow
Work ships as user stories, one branch and one pull request each.
1. Create a branch, e.g. `us-1-country-list`.
2. Write the spec in `docs/specs/` and commit it first: `docs(spec): US-1 country list`.
3. The ACs are approved before any test is written.
4. Implement test-first ([The loop](#the-loop)).
5. Update the README requirements map.
6. Run `scripts/lint.sh` and `scripts/test-matrix.sh` locally, then open a pull request with the AC checklist, how to verify it, and, for UI changes, the snapshot diffs.
7. When CI is green, merge with a merge commit, never squash, so the story's commits stay in history.

**Specs are committed; plans are not.** A spec records what a story delivers and is kept up to date: if scope changes mid-story, the spec changes in its own `docs(spec): …` commit, and ACs are ticked as their tests land. Implementation plans are working notes and stay out of the repo.

### Spec sections
1. Story, scope and non-goals.
2. Acceptance criteria, numbered `AC-<story>.<n>`.
3. For UI stories, screen contract tables: State → UI, and Interaction → event → effect.
4. Data layer: operations, mapping, repository.
5. Domain types.
6. Errors and edge cases: Scenario | Expected | UI state | Recovery.
7. Test plan: AC → test name.
8. Decisions, each with its rejected alternative, and anything still open together with what will settle it.

### The loop
1. Pick an AC.
2. Write a failing test named after it, e.g. `@Test("AC-1.5 no match shows empty state")`. **Red commits must compile:** a test against an API that doesn't exist yet is a build failure, not a red test, so write it against a stub that builds and returns the wrong value. If a stub isn't practical, commit the test and the implementation together.
3. Write the smallest implementation that passes.
4. Refactor.
5. Tick the AC in the spec.

Commits follow Conventional Commits and show the flow: `test(list): …` (red), `feat(list): …` (green), `refactor(list): …`. Keep them small and focused.

### Definition of Done
- Every AC has a test (or, for setup work, a verification command), and the spec's ACs are ticked.
- `scripts/lint.sh` is clean.
- `scripts/test-matrix.sh` passes on every row.
- Previews cover every state in light, dark and the largest accessibility size.
- Every UI change ships snapshots of each affected state on every preset, in light and dark, inspected before committing.
- Every new string is in the String Catalog with a translator comment, the localization tests pass, and the pseudolanguage checks are clean.
- The README requirements map and decisions are up to date.

## Test matrix
`scripts/test-matrix.sh` runs a clean build and the test plan on each row, and fails if the build reports any warning. It selects Xcode per run with `DEVELOPER_DIR` and never changes `xcode-select`. Override the Xcode paths with `XCODE_27_PATH` and `XCODE_26_PATH`.

| Xcode | Simulator | Runs |
|---|---|---|
| 27.1 | iPhone 17 Pro, iOS 27.0 | build + full test plan, including snapshots (reference row) |
| 27.1 | iPhone 15 Pro, iOS 17.0 | test plan without snapshots (deployment-target floor) |
| 26.0.1 | iPhone 17 Pro, iOS 26.0 | build + test plan without snapshots |

## Snapshot tests
Snapshot tests live in the `CountriesUISnapshotTests` target. Reference images are recorded and compared only on the reference row: Xcode 27.1 with the iOS 27.0 simulator. (Xcode 27.1's simulator runtime for iPhones and iPads is iOS 27.0; its iOS 27.1 runtime supports only iPhone Duo.)
- **Record:** run the `RecordSnapshots` test plan. It sets `SNAPSHOT_RECORD=1`, writes the reference PNGs next to the test files, and fails every snapshot test on purpose, so a recording run can never pass in CI.
- **Review:** open every new or changed PNG before committing. Pull requests show image diffs.
- **On a mismatch:** the failure message has the path of the new image in the temporary directory. Compare it with the reference; if the change is intended, record again.

## Codegen
The GraphQL schema, the operations (`*.graphql`) and the generated Swift live in `Packages/CountriesData/Sources/CountriesData/`. Generated code is committed, so building never needs codegen. To change an operation, edit its `.graphql` file and regenerate; commit the generated changes with it. Details are added when codegen is set up.

## Adding a language
1. Add the language to the app project's localizations (Project → Info → Localizations). iOS loads a package's translations only for languages the app declares.
2. Add it to `Localizable.xcstrings` and translate every key.
3. Run the localization tests: they fail on any missing translation.
4. Record that language's snapshots.
