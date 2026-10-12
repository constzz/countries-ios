# Atlas

[![CI](https://github.com/constzz/countries-ios/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/constzz/countries-ios/actions/workflows/ci.yml?query=branch%3Amain)
[![Snapshots](https://github.com/constzz/countries-ios/actions/workflows/snapshots.yml/badge.svg?branch=main)](https://github.com/constzz/countries-ios/actions/workflows/snapshots.yml?query=branch%3Amain)

Atlas is an iOS app for browsing the world's countries from the public [Countries GraphQL API](https://countries.trevorblades.com). I built it as a take-home exercise in SwiftUI and Apollo iOS. Search the list by name, then open a country to see its capital, currencies, languages and continent.

<p>
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_LIST_LOADED_iPhone17Pro_light.png" width="200" alt="The country list in light mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPhone17Pro_light.png" width="200" alt="Bolivia's details in light mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_LIST_LOADED_iPhone17Pro_dark.png" width="200" alt="The country list in dark mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPhone17Pro_dark.png" width="200" alt="Bolivia's details in dark mode">
</p>
<img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPad11Landscape_light.png" width="816" alt="The list and Bolivia's details side by side on iPad">

These are the snapshot tests' reference images, so CI fails when a screen no longer matches them.

## Build and run
- **Xcode:** 26.0.1 or later. CI builds on 26.0.1 and 27.1; I developed on 27.1 (27A9269).
- **Deployment target:** iOS 17.0, the first release with the Observation framework.
- **Simulator:** any iPhone or iPad with iOS 17.0 or later. I used the iPhone 17 Pro with iOS 27.0, the only one the [snapshots](#ci) run on.

Open `Atlas.xcodeproj` and press ⌘R; there's nothing to install. To see the other states, search "zzz" for the empty state, open Antarctica for "None" values, or go offline for the error states. ⌘U runs the tests, and the other commands are in [DEVELOPMENT.md](docs/DEVELOPMENT.md#commands).

## CI
On every pull request, [ci.yml](.github/workflows/ci.yml) runs [lint](scripts/lint.sh), the [codegen check](scripts/check-codegen.sh) and the tests on Xcode 26.0.1 and 27.1, and [snapshots.yml](.github/workflows/snapshots.yml) compares the snapshots on Xcode 27.1. Any warning fails the build. The snapshots run only on the iPhone 17 Pro simulator with iOS 27.0, so pick it and press ⌘U to run them locally.

## Code walkthrough
| | Country list | Country detail |
|---|---|---|
| View: owns the view model | [`CountryListView`](Packages/AtlasUI/Sources/AtlasUI/CountryList/Views/CountryListView.swift) | [`CountryDetailView`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/Views/CountryDetailView.swift) |
| Content: draws a state | [`CountryListContent`](Packages/AtlasUI/Sources/AtlasUI/CountryList/Views/CountryListContent.swift) | [`CountryDetailContent`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/Views/CountryDetailContent.swift) |
| View model | [`CountryListViewModel`](Packages/AtlasUI/Sources/AtlasUI/CountryList/ViewModel/CountryListViewModel.swift) | [`CountryDetailViewModel`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/ViewModel/CountryDetailViewModel.swift) |
| Use case | [`GetCountriesUseCase`](Packages/AtlasDomain/Sources/AtlasDomain/GetCountriesUseCase.swift) | [`GetCountryDetailsUseCase`](Packages/AtlasDomain/Sources/AtlasDomain/GetCountryDetailsUseCase.swift) |
| Repository method | [`countries(matching:forceRefresh:)`](Packages/AtlasData/Sources/AtlasData/CountriesRepositoryImpl.swift) | [`country(code:)`](Packages/AtlasData/Sources/AtlasData/CountriesRepositoryImpl.swift) |
| GraphQL query | [`CountriesQuery`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountriesQuery.graphql) | [`CountryQuery`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountryQuery.graphql) |
| Tests | [view model](Packages/AtlasUI/Tests/AtlasUITests/CountryListViewModelTests.swift), [search input](Packages/AtlasUI/Tests/AtlasUITests/CountryListSearchInputTests.swift), [snapshots](AtlasUISnapshotTests/CountryListSnapshotTests.swift) | [view model](Packages/AtlasUI/Tests/AtlasUITests/CountryDetailViewModelTests.swift), [snapshots](AtlasUISnapshotTests/CountryDetailSnapshotTests.swift) |

[`AppContainer`](Atlas/AppContainer.swift) builds the repository and the use cases, and [`RootView`](Packages/AtlasUI/Sources/AtlasUI/RootView.swift) shows both screens in a `NavigationSplitView`.

## Architecture
```
                       Atlas
           ┌─────────────┼──────────────┐
           ▼             ▼              ▼
        AtlasUI ──► AtlasDomain ◄── AtlasData ──► Apollo iOS
           │
           ▼
        AtlasMVI
```

AtlasDomain holds the models, the use cases and the repository protocol, and imports only Foundation. Every request goes view model → use case → repository → data sources ([API](Packages/AtlasData/Sources/AtlasData/DataSources/CountriesRemoteDataSourceImpl.swift) and [memory](Packages/AtlasData/Sources/AtlasData/DataSources/InMemoryCache.swift)). Every target builds in Swift 6 mode with complete concurrency checking, and a warning fails the build.

- **MVI:** both view models subclass [`MVIViewModel`](Packages/AtlasMVI/Sources/AtlasMVI/MVIViewModel.swift). The view sends actions, `reduce` is the only place the state changes, finished work comes back as events, and one-time UI events go out as effects. Views see only `state`, `send` and `effects()` ([details](docs/ARCHITECTURE.md#presentation)).
- **Concurrency:** view models are `@MainActor @Observable`, owned by their view in `@State`. Every call from a view model down to Apollo is `async throws`, and Combine only debounces the search field ([details](docs/ARCHITECTURE.md#concurrency)).
- **Apollo:** only AtlasData imports it, and codegen writes `internal` types there, so the UI never sees them. Both queries share the [`CountryBasics`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountryBasics.graphql) fragment ([details](docs/ARCHITECTURE.md#atlasdata)).
- **Testing:** 124 Swift Testing tests, none of them on the network. Each layer is tested over doubles of the one below, no test sleeps, and [`assertSnapshots`](AtlasUISnapshotTests/Helpers/AssertSnapshots.swift) renders iPhone, iPhone Duo and iPad in light and dark, the largest text size and right-to-left ([details](docs/ARCHITECTURE.md#testing)).

## Key decisions
- **Search runs on the server.** The app sends the term to the API's `name` filter 300 ms after typing stops. Matching then happens in one place for every client and can grow, for example to ignore accents, without repeating the logic in each app. Filtering a downloaded list on the device would also leave no queries to debounce, and the brief asks for debounced queries.
- **MVI on a small shared base.** A screen's state changes only in `reduce`, so even an old search answering after a newer one is [a plain test](Packages/AtlasUI/Tests/AtlasUITests/CountryListViewModelTests.swift#L260): send actions, check the state. The base is my own [`MVIViewModel`](Packages/AtlasMVI/Sources/AtlasMVI/MVIViewModel.swift), 120 lines, not a framework like TCA.
- **One request at a time.** A new load, search, refresh or retry cancels the running request, and a cancelled request never changes the screen.
- **View models go through use cases.** Rules about the data stay out of the view models: `GetCountriesUseCase` sorts by name, because the API sorts by code. `GetCountryDetailsUseCase` only forwards the call, but I kept it so both screens get their data the same way.
- **The detail screen loads its own data.** It gets only the country code. Passing in the list's row would show the name and flag sooner, but the detail screen would depend on the list.

## Left out
- **A custom EnvironmentValues entry.** The brief asks for one only where more than one view needs the value, and only the root view reads the use cases. The custom ViewModifier, `.loadState`, is in.
- **Search that ignores accents.** The API matches names as written, so "Reunion" doesn't find "Réunion". The fix belongs on the server, with the rest of the matching.
- **Translated country names.** Search matches the English names the API returns, so the names stay in English.
- **Git LFS for the snapshot images.** They take 8 MB, and with LFS a clone without `git lfs` installed would get placeholders and fail the snapshot tests.

## With more time
- **UI tests** for navigation, going back, size changes and relaunch, which I check by hand today.
- **A disk data source**, so a cold start offline still shows the last list. Only the repository would change.
- **A design-system package, then a package per feature**, once a third screen or a second team makes the extra targets worth it.
- **More snapshots:** iPad multitasking sizes and the iPhone Duo's rotated postures.

## How I worked
Each story started with a spec in [`docs/specs`](docs/specs) and its acceptance criteria, then tests, then code. Red commits compile, and a test that covers a criterion starts its name with it, such as `AC-1.5`. Each story merged as its own pull request; #4 to #17 are review and cleanup.

| Story | Spec | Pull request |
|---|---|---|
| US-0 Project setup | [us-0-project-setup.md](docs/specs/us-0-project-setup.md) | [#1](https://github.com/constzz/countries-ios/pull/1) |
| US-1 Country list | [us-1-country-list.md](docs/specs/us-1-country-list.md) | [#2](https://github.com/constzz/countries-ios/pull/2) |
| US-2 Country detail | [us-2-country-detail.md](docs/specs/us-2-country-detail.md) | [#3](https://github.com/constzz/countries-ios/pull/3) |

## Requirements map
Each line of the brief, in the brief's order, with the acceptance criterion that covers it and what checks it.

<details>
<summary>Show the map</summary>

| Requirement | Story / AC | Checked by |
|---|---|---|
| **List screen** | | |
| All countries with flag emoji, name and continent | US-1 / AC-1.1 | `CountryListViewModelTests`, `GetCountriesUseCaseTests`, `COUNTRY_LIST_LOADED_*` snapshots |
| A search field that filters by country name | US-1 / AC-1.3 | `SearchPatternTests`, `CountriesRemoteDataSourceTests` |
| A debounce, so typing doesn't send a query per keystroke | US-1 / AC-1.2 | `CountryListSearchInputTests`: "typing searches once, 300 ms after the last keystroke" |
| Distinct loading, empty and error states | US-1 / AC-1.4 to AC-1.6, AC-1.9 | `CountryListViewModelTests`, `CountryListSnapshotTests` |
| Tapping a country opens the detail screen | US-2 / AC-2.1 | checked by hand; UI tests are under [With more time](#with-more-time) |
| **Detail screen** | | |
| Name, flag emoji, capital, currency, languages and continent | US-2 / AC-2.2, AC-2.3 | `CountryDetailsMapperTests`, `CountryDetailViewModelTests`, `COUNTRY_DETAIL_*` snapshots |
| Loading and error states | US-2 / AC-2.4 to AC-2.6 | `CountryDetailViewModelTests`, `CountryDetailSnapshotTests` |
| **Both screens** | | |
| Optional: light and dark mode with semantic colours only | US-1 / AC-1.9, US-2 / AC-2.6 | system colours only, through `Palette`; every snapshot in light and dark |
| Optional: Dynamic Type, usable at accessibility sizes | US-1 / AC-1.9, US-2 / AC-2.6 | `*_accessibilityXXXL` snapshots |
| **1. Modular structure** | | |
| At least two local packages, data and UI; the app target only composes | US-0 / AC-0.6 | AtlasData, AtlasUI, AtlasDomain and AtlasMVI; `Atlas/` holds the entry point and `AppContainer` |
| The UI doesn't depend on Apollo types; mapping at the data boundary | US-0 / AC-0.6 | AtlasUI has no Apollo dependency; generated code is `internal` to AtlasData, and its mappers build domain models |
| Strict concurrency, no warnings | US-0 / AC-0.2 | Swift 6 language mode and warnings as errors in every target, built on Xcode 26.0.1 and 27.1 in CI |
| **2. Networking** | | |
| Apollo iOS with the downloaded schema and codegen | US-0 / AC-0.5 | [`schema.graphqls`](Packages/AtlasData/Sources/AtlasData/GraphQL/schema.graphqls), [`apollo-codegen-config.json`](apollo-codegen-config.json); CI checks codegen reproduces the committed files |
| List and detail operations, sharing a fragment | US-1, US-2 | `CountriesQuery` and `CountryQuery`, both spreading `CountryBasics` |
| The network layer behind a protocol | — | `CountriesRepository` in AtlasDomain; `CountriesRemoteDataSource` and `GraphQLClient` in AtlasData |
| async/await, no completion handlers | — | every call from a view model down to Apollo is `async throws` |
| A network error shows an error state, not a crash or a silent empty list | US-1 / AC-1.6, US-2 / AC-2.4 | `CountryListViewModelTests`, `CountryDetailViewModelTests`, `ErrorMappingTests`, `ErrorCopyTests`; `CountriesRemoteDataSourceTests`: "no countries for a blank term is a server error" |
| **3. State and views** | | |
| `@Observable` view models with `@MainActor` | — | both view models subclass `MVIViewModel`, which is `@MainActor @Observable` |
| Combine for the search debounce | US-1 / AC-1.2 | `CountryListSearchInputTests` |
| Optional: a custom ViewModifier and EnvironmentValues entry, each used by more than one view | — | `.loadState`, used by both screens; the environment entry is [left out](#left-out) |
| Stable row identity across reloads and filtering | US-1 / AC-1.7 | `CountryListViewModelTests`: "rows keep their codes across refresh and filtering" |
| **4. Tests** | | |
| List view model: successful load, empty results and a network failure, over a mocked network boundary | US-1 / AC-1.1, AC-1.5, AC-1.6 | `CountryListViewModelTests` over `MockCountriesRepository`: "a response shows the loaded rows", "no match shows the empty state with the query", "a failure shows the error" |
| At least one test of the GraphQL to domain mapping | US-1 / AC-1.1, US-2 / AC-2.2, AC-2.3 | `CountrySummaryMapperTests`, `CountryDetailsMapperTests` |
| Swift Testing or XCTest, with no network requests | — | 124 Swift Testing tests over doubles; `StubURLSession` under a real `ApolloClient` |
| **Submission** | | |
| A public repository with its commit history | — | this repository; each story merged as a pull request with a merge commit |
| Build and run instructions with the Xcode version, deployment target and simulator | — | [Build and run](#build-and-run) |
| Key decisions, what's left out, and what I'd change with more time | — | [Key decisions](#key-decisions), [Left out](#left-out), [With more time](#with-more-time) |
| SwiftFormat and SwiftLint configuration | US-0 / AC-0.4 | [`.swiftformat`](.swiftformat), [`.swiftlint.yml`](.swiftlint.yml); `scripts/lint.sh` in CI |

</details>
