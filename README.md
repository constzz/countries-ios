# Countries

A SwiftUI app for browsing the world's countries, backed by the public [Countries GraphQL API](https://countries.trevorblades.com) through Apollo iOS. Search the list by name, then open a country to see its capital, currencies, languages and continent.

## Build and run
**Requirements:** Xcode 26.0.1 or later, iOS 17.0 or later.

Open `CountriesApp.xcodeproj` and press ⌘R. Nothing else needs installing: the generated GraphQL code is committed, and Apollo iOS is the only package dependency.

Developed with Xcode 27.1 (27A9269) on the iPhone 17 Pro / iOS 27.0 simulator.

### Tested with
| Xcode | Simulator | Local | CI |
|---|---|---|---|
| 27.1 | iPhone 17 Pro, iOS 27.0 | | |
| 27.1 | iPhone 15 Pro, iOS 17.0 | | |
| 26.0.1 | iPhone 17 Pro, iOS 26.0 | | |

### Commands
| Task | Command |
|---|---|
| All tests | `xcodebuild test -scheme CountriesApp -testPlan CountriesApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0'` |
| Test matrix (Xcode 26 and 27) | `scripts/test-matrix.sh` |
| Lint | `scripts/lint.sh` (needs `brew install swiftlint swiftformat`) |
| Record snapshots | the `RecordSnapshots` test plan ([details](docs/DEVELOPMENT.md#snapshot-tests)) |
| Codegen | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#codegen) |

To check right-to-left layout or long text: Edit Scheme → Run → Options → App Language → Right-to-Left Pseudolanguage or Double-Length Pseudolanguage.

## Architecture
Three local Swift packages with one dependency direction: `CountriesUI → CountriesDomain ← CountriesData`. The domain package defines the models, the repository protocol and the error type. The data package implements the repository with Apollo iOS and keeps every generated type internal. The UI package has the screens and their `@MainActor @Observable` view models, and never sees Apollo. The app target composes the three.

```
                      CountriesApp
              │               │               │
              ▼               ▼               ▼
        CountriesUI ──► CountriesDomain ◄── CountriesData ──► Apollo iOS
```

More in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/UI_GUIDELINES.md](docs/UI_GUIDELINES.md) and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Delivery
The work ships as user stories, each with its own spec, branch and pull request:

| Story | Spec |
|---|---|
| US-0 Project setup | [us-0-project-setup.md](docs/specs/us-0-project-setup.md) |
| US-1 Country list | added with the story |
| US-2 Country detail | added with the story |

## Requirements map
Each requirement of the task traces to an acceptance criterion and the test that checks it. Filled in per story.

| Requirement | Story / AC | Test |
|---|---|---|
| At least two local Swift packages (data and UI) | US-0 / AC-0.6 | build |
| Swift 6 strict concurrency | US-0 / AC-0.2 | warnings-as-errors build |
| SwiftLint and SwiftFormat | US-0 / AC-0.4 | `scripts/lint.sh` |

## How to see each state
- Snapshot images: every screen state on every device, in light and dark, under `snapshots/` next to the snapshot tests.
- SwiftUI previews for each screen.

## Key decisions
Filled in per story.

## Left out
Filled in per story.

## With more time
Filled in per story.
