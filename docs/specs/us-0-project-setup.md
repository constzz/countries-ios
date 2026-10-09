# US-0: Project setup

*As a reviewer or developer, I can clone the repo, open it in Xcode, and run the app, its tests and its linters, so every feature story lands on a working, warning-free baseline.*

## Scope
- `CountriesApp.xcodeproj` with an app target and three local packages under `Packages/`: `CountriesDomain`, `CountriesData` (Apollo iOS) and `CountriesUI`, wired as `UI → Domain ← Data`, with the app composing all three.
- A placeholder root screen in `CountriesUI` whose title comes from the String Catalog.
- Swift 6 language mode and strict concurrency everywhere, iOS 17.0 deployment target, zero warnings on Xcode 26.0.1 and Xcode 27.1.
- One test plan (`CountriesApp.xctestplan`) that runs every package test target, an app-hosted snapshot test target with its own helper, and localization tests.
- SwiftLint and SwiftFormat configs, `scripts/lint.sh`, `scripts/test-matrix.sh` and a CI workflow.
- Apollo iOS 2.4.0 with the codegen config, the downloaded schema and the generated code committed.
- App identity: display name, bundle ID, launch screen and app icon.
- Docs: `README.md`, `docs/ARCHITECTURE.md`, `docs/UI_GUIDELINES.md`, `docs/DEVELOPMENT.md`.

**Non-goals:** domain models, feature queries and feature UI (US-1 and US-2).

## Acceptance criteria
- [ ] **AC-0.1** A fresh clone builds and launches on the iPhone 17 Pro / iOS 27.0 simulator with ⌘R, without running codegen or installing any tool.
- [ ] **AC-0.2** The app and all local package targets build with zero warnings, and any new warning fails the build.
- [ ] **AC-0.3** One `xcodebuild test` command with the `CountriesApp` test plan runs every package test target, and `swift test` runs the `CountriesDomain` and `CountriesData` tests on macOS.
- [ ] **AC-0.4** `scripts/lint.sh` passes (SwiftLint strict, SwiftFormat lint), with generated code excluded.
- [ ] **AC-0.5** The documented codegen command regenerates the committed Swift files with no diff.
- [ ] **AC-0.6** `CountriesUI` has no dependency on Apollo, and no public API of `CountriesData` exposes a generated type.
- [ ] **AC-0.7** CI runs lint, build and tests on the pull request and passes.
- [ ] **AC-0.8** `scripts/test-matrix.sh` passes on every row: Xcode 27.1 on iOS 27.0 and on iOS 17.0, and Xcode 26.0.1 on iOS 26.0, with warnings as errors. The project still opens in Xcode 26.0.1 after being saved in Xcode 27.1.
- [ ] **AC-0.9** Snapshots of the placeholder screen pass on every device preset (iPhone 17 Pro, iPhone Duo folded and unfolded, iPad 11-inch portrait and landscape) in light and dark, plus accessibility XXXL on iPhone 17 Pro. They run only on Xcode 27.1 with the iOS 27.0 simulator and are skipped elsewhere with a visible reason. Two consecutive recordings produce byte-identical PNGs.
- [ ] **AC-0.10** The placeholder title comes from `Localizable.xcstrings`, and its right-to-left snapshot is mirrored. The localization tests pass, and a `Text("…")` without `bundle:` in `CountriesUI` fails lint.
- [ ] **AC-0.11** The app installs as "Countries" with the bundle ID `$(BUNDLE_ID_PREFIX).countries`, an app icon with light, dark and tinted variants, and a system-background launch screen. Every commit is authored as Kostiantyn Bezzemelnyi.

## Verification
| AC | How it is checked |
|---|---|
| 0.1 | Clone into a temporary folder, then `xcodebuild build` and `simctl install` + `launch` with Homebrew tools removed from `PATH` |
| 0.2 | A clean `xcodebuild build` on each Xcode; the result bundle reports zero warnings (`xcrun xcresulttool get build-results`) |
| 0.3 | The test command from the README; the result bundle lists every package test target; `swift test --package-path Packages/<name>` |
| 0.4 | `scripts/lint.sh` exits 0 |
| 0.5 | Run the codegen command, then `git diff --exit-code` |
| 0.6 | `CountriesUI/Package.swift` declares only `CountriesDomain`; generated types are `internal`, so exposing one publicly fails to compile; a lint rule rejects `import Apollo` in `CountriesUI` |
| 0.7 | `gh pr checks` on PR #1 is green |
| 0.8 | `scripts/test-matrix.sh` exits 0; after a save in Xcode 27.1, `project.pbxproj` still has `objectVersion = 77` and the Xcode 26.0.1 row still builds it |
| 0.9 | Snapshot test target on the reference row; record twice and compare checksums; inspect the dark, accessibility-size and iPad images |
| 0.10 | Localization tests in `CountriesUITests`; inspect the right-to-left image; lint a temporary file containing `Text("x")` |
| 0.11 | Read `CFBundleDisplayName` and `CFBundleIdentifier` from the installed app; home-screen screenshots in light, dark and tinted; `git log --format=%an \| sort -u` |

## Decisions
- **Plain `.xcodeproj` with local Swift packages.** Clone, open, ⌘R works with no generator installed. Rejected: Tuist or XcodeGen, which add a setup step for reviewers.
- **One UI package with a folder per feature** (`CountryList/`, `CountryDetail/`, `DesignSystem/`). The split view composes both screens and their shared selection, and both use the same state views, environment entry and String Catalog. Rejected: a package per feature, which would add a shared design-system package, a catalog and test targets per package, and a composition package, for two screens. The folders mark where packages would split if a feature grew.
- **iOS 17.0 minimum.** The Observation framework (`@Observable`) and `ContentUnavailableView` need iOS 17, and neither is back-deployed. Rejected: iOS 16 with a third-party Observation backport.
- **Builds on Xcode 26.0.1 and 27.1.** Code targets Swift 6.2 and the iOS 26 SDK, so no newer language features or SDK APIs are used. The project file uses the "Xcode 16.0" format (`objectVersion = 77`): Xcode 26.0.1 knows no format newer than "Xcode 16.3", while Xcode 27.1 defaults to "Xcode 27.0".
- **Warnings are errors in every build of our own code**, through `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `Config/Shared.xcconfig` and `.treatAllWarnings(as: .error)` in each local package. Rejected: passing `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` on the command line in CI only, which also reaches Apollo, whose warnings Xcode suppresses, and fails with conflicting compiler options.
- **Reference simulator: iPhone 17 Pro on iOS 27.0.** Xcode 27.1's simulator runtime for iPhones and iPads is iOS 27.0; the iOS 27.1 runtime supports only iPhone Duo. Snapshot images are recorded and compared on iOS 27.0, and the iPhone Duo presets use measurements from its iOS 27.1 simulator.
- **Lint and format run from Homebrew via `scripts/lint.sh` and CI.** Rejected: Xcode build-tool plugins, which ask every reviewer to trust and enable them.
- **Generated Apollo code is committed and `internal` to `CountriesData`.** Reviewers never run codegen, and the compiler keeps generated types inside the data package. Rejected: generating at build time.
- **Snapshot tests use a small helper written for this repo, in a test target hosted by the app** (`CountriesUISnapshotTests`). A SwiftUI view is hosted in a window that joins the test host's window scene, with a fixed size, safe area and traits; it is rendered with `drawHierarchy` to an sRGB PNG and compared byte for byte with a committed reference image. Rejected: a test target in the CountriesUI package, which has no host app and so no window scene: Liquid Glass then renders without its material. Rejected: a third-party snapshot library, which would be the only test dependency and needs a host app for glass too.
- **Device presets come from the simulators.** Safe areas and size classes were read from running iPhone 17 Pro, iPad (A16) and iPhone Duo simulators. The iPhone Duo opens its inner screen at 951 × 669 pt, so that is the unfolded preset; its rotated and folded-landscape postures are left for later.
- **String Catalog from the start.** All copy lives in `CountriesUI/Resources/Localizable.xcstrings` and is looked up with `bundle: .module`. The app ships in English, and adding a language needs no code changes.

## Open until settled in this story
- Which Xcode versions and simulator runtimes the GitHub macOS runner image provides.
