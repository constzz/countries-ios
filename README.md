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
- **Deployment target:** iOS 17.0, the first release with the Observation framework. I ran the tests, all but the snapshots, on an iPhone 15 Pro simulator with iOS 17.0 locally; CI can't, because GitHub's macOS images don't have the iOS 17.0 simulator.
- **Simulator:** iPhone 17 Pro, iOS 27.0.

Open `Atlas.xcodeproj` and press ⌘R; there's nothing to install. To see the other states, search "zzz" for the empty state, open Antarctica for "None" values, or go offline for the error states. ⌘U runs the tests, and the other commands are in [DEVELOPMENT.md](docs/DEVELOPMENT.md#commands).

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
- **The repository has its own cache, and Apollo's is off.** It keeps only successful results, in memory until the app quits; pull-to-refresh skips it, and Try Again always reaches the network. Apollo's cache also stored responses with GraphQL errors, so a country that failed once read back as "not found".
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
Each requirement in the brief, the acceptance criterion that covers it, and what checks it.

<details>
<summary>Show the map</summary>

| Requirement | Story / AC | Checked by |
|---|---|---|
| At least two local Swift packages, data and UI; the app target only composes | US-0 / AC-0.6 | build; `AtlasUI` has no Apollo dependency |
| The UI never sees Apollo-generated types | US-0 / AC-0.6 | generated code is `internal` to AtlasData |
| Strict concurrency, no warnings | US-0 / AC-0.2 | warnings-as-errors build on Xcode 26.0.1 and 27.1 |
| Schema downloaded, codegen configured | US-0 / AC-0.5 | [`apollo-codegen-config.json`](apollo-codegen-config.json); codegen reproduces the committed files with no diff |
| SwiftLint and SwiftFormat | US-0 / AC-0.4 | `scripts/lint.sh` in CI |
| A list of countries with flag, name and continent | US-1 / AC-1.1 | `GetCountriesUseCaseTests`, `CountriesRepositoryTests`, `CountryListViewModelTests`, `COUNTRY_LIST_LOADED_*` snapshots |
| Search by name, debounced with Combine | US-1 / AC-1.2, AC-1.3 | `CountryListSearchInputTests`, `SearchPatternTests`, `CountriesRemoteDataSourceTests` |
| Loading, empty and error states | US-1 / AC-1.4 to AC-1.6, AC-1.9 | `CountryListViewModelTests`, `ErrorCopyTests`, `CountryListSnapshotTests` |
| Stable row identity across reloads and filtering | US-1 / AC-1.7 | `CountryListViewModelTests`; a country's `code` is its `id` |
| `@Observable` and `@MainActor` view models | US-1 / AC-1.1, AC-1.11 | `CountryListViewModelTests` |
| A protocol over the network layer; async/await only | — | `CountriesRepository` in AtlasDomain; `CountriesRemoteDataSource` and `GraphQLClient` in AtlasData |
| Failures show an error state | US-1 / AC-1.6, US-2 / AC-2.4 | `CountryListViewModelTests`, `CountryDetailViewModelTests`, `ErrorCopyTests` |
| Tests with a mocked network boundary | US-1 / AC-1.1, AC-1.3, AC-1.8, US-2 / AC-2.4 | `FakeGraphQLClient` and `FakeCountriesRemoteDataSource` in the data tests, `StubURLSession` under a real `ApolloClient`, `MockCountriesRepository` under the use cases and view models |
| A test of the GraphQL to domain mapping | US-1 / AC-1.1, US-2 / AC-2.2, AC-2.3 | `CountrySummaryMapperTests`, `CountryDetailsMapperTests` |
| Tap a country to see its name, flag, capital, currencies, languages and continent | US-2 / AC-2.1 to AC-2.3 | `CountryDetailsMapperTests`, `CountryDetailViewModelTests`, `COUNTRY_DETAIL_*` snapshots; navigation checked by hand |
| A fragment shared by both screens' operations | US-2 | `CountryBasics.graphql`, spread by `CountriesQuery` and `CountryQuery` |
| Detail loading and error states | US-2 / AC-2.4, AC-2.5, AC-2.10 | `CountryDetailViewModelTests`, `CountriesRepositoryTests`, `ErrorCopyTests`, `CountryDetailSnapshotTests` |
| Optional: light and dark mode with semantic colors | US-1 / AC-1.9, US-2 / AC-2.6 | system colors only, through `Palette`; every snapshot in light and dark |
| Optional: Dynamic Type at accessibility sizes | US-1 / AC-1.9, US-2 / AC-2.6 | `*_accessibilityXXXL` snapshots |
| Optional: a custom ViewModifier and EnvironmentValues entry | — | `.loadState`, used by both screens; the environment entry is [left out](#left-out) |

</details>
