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
| All tests | `xcodebuild test -scheme CountriesApp -testPlan CountriesApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' -collect-test-diagnostics never` |
| Package tests on macOS | `swift test --package-path Packages/CountriesData` (also `CountriesDomain`) |
| Lint | `scripts/lint.sh` |
| Format, then lint | `scripts/lint.sh --fix` |
| Test matrix | `scripts/test-matrix.sh` |
| Record snapshots | see [Snapshot tests](#snapshot-tests) |
| Codegen | see [Codegen](#codegen) |
| Check the generated code is current | `scripts/check-codegen.sh` |

`-collect-test-diagnostics never` stops `xcodebuild` from collecting a sysdiagnose from the simulator after a failing test, which can take 10 minutes.

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
6. Run `scripts/lint.sh` locally, then open a pull request with the AC checklist, how to verify it, and, for UI changes, the snapshot diffs.
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
- CI is green: it runs the `xcode26-ios26` and `xcode27-ios27` rows of `scripts/test-matrix.sh`. Locally, run only the tests a change touches.
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
Snapshot tests live in `CountriesUISnapshotTests/`, a unit-test target in the Xcode project hosted by the app (a package test target has no window scene, so Liquid Glass wouldn't render). Its helpers are in `Helpers/`, and reference images in `snapshots/` next to the test files. Reference images are recorded and compared only on the reference row: Xcode 27.1 with the iOS 27.0 simulator. (Xcode 27.1's simulator runtime for iPhones and iPads is iOS 27.0; its iOS 27.1 runtime supports only iPhone Duo.)
- **Record:** run the `RecordSnapshots` test plan. It sets `SNAPSHOT_RECORD=1`, writes the reference PNGs, and fails every snapshot test on purpose, so a recording run can never pass in CI. From the command line:
  ```sh
  xcodebuild test -scheme CountriesApp -testPlan RecordSnapshots -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' -collect-test-diagnostics never
  ```
- **How an image is made:** each one is drawn at @1x, while the window keeps the device's display scale, so layout matches the device and the images stay small. Renders run one at a time, because every snapshot window joins the host app's scene and Liquid Glass in one picks up another on screen. UIKit animations are off, animations with a finite duration (a spinner's frames, a fade) are removed before each capture so layers draw their final state, and the helper captures until two images taken 50 ms apart match. No capture counts while an image view holds an image its layer doesn't show yet: on a fresh simulator, as in CI, system images such as the search field's clear button take a few seconds to draw the first time. Animations of infinite duration stay: Liquid Glass uses them to tie its shapes to other layers.
- **Comparison:** an image matches its reference when no color channel differs by more than 2 of 255. Liquid Glass over a search field holding text varies by that much between runs; any change to layout, text or color differs by far more.
- **Review:** open every new or changed PNG before committing. Pull requests show image diffs.
- **On a mismatch:** the rendered image is attached to the test result (in Xcode's test report, or in the result bundle CI uploads). Compare it with the reference; if the change is intended, record again.
- **Off the reference simulator** snapshot tests are skipped, and a recording run fails.

## Codegen
Apollo's inputs live in `Packages/CountriesData/Sources/CountriesData/GraphQL/`: the downloaded `schema.graphqls` and the operations (`*.graphql`). The generated Swift goes to `Generated/` next to it, `internal` to CountriesData. Both are committed, so building never needs codegen. Settings are in `apollo-codegen-config.json`.

Generated code is never edited by hand or by a formatter: SwiftLint and SwiftFormat exclude `**/Generated`, and `Generated/.swift-format-ignore` keeps the swift-format that ships with Xcode out too. Codegen keeps that file.

1. Install the CLI once, at the repo root (it's gitignored). Its version must match Apollo's in `Package.resolved`; the CLI refuses a mismatch.
   ```sh
   curl -L https://github.com/apollographql/apollo-ios/releases/download/2.4.0/apollo-ios-cli.tar.gz | tar -xz
   ```
2. After editing a `.graphql` file, regenerate and commit the operation and the generated Swift together:
   ```sh
   ./apollo-ios-cli generate --path ./apollo-codegen-config.json
   ```
   CI runs `scripts/check-codegen.sh`, which regenerates and fails if the committed files differ.
3. Only when the API itself changes, download the schema again first:
   ```sh
   ./apollo-ios-cli fetch-schema --path ./apollo-codegen-config.json
   ```

## Adding a language
1. Add the language to the app project's localizations (Project → Info → Localizations). iOS loads a package's translations only for languages the app declares.
2. Add it to `Localizable.xcstrings` and translate every key.
3. Run the localization tests: they fail on any missing translation.
4. Record that language's snapshots.
