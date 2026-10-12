# Atlas

[![CI](https://github.com/constzz/countries-ios/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/constzz/countries-ios/actions/workflows/ci.yml?query=branch%3Amain)
[![Snapshots](https://github.com/constzz/countries-ios/actions/workflows/snapshots.yml/badge.svg?branch=main)](https://github.com/constzz/countries-ios/actions/workflows/snapshots.yml?query=branch%3Amain)

Atlas browses the world's countries from the public [Countries GraphQL API](https://countries.trevorblades.com). I built it as a take-home exercise: SwiftUI and Apollo iOS, split into local Swift packages, with a data layer that's tested without the network. Search the list by name, then open a country to see its capital, currencies, languages and continent.

<p>
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_LIST_LOADED_iPhone17Pro_light.png" width="200" alt="The country list in light mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPhone17Pro_light.png" width="200" alt="Bolivia's details in light mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_LIST_LOADED_iPhone17Pro_dark.png" width="200" alt="The country list in dark mode">
  <img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPhone17Pro_dark.png" width="200" alt="Bolivia's details in dark mode">
</p>
<img src="AtlasUISnapshotTests/snapshots/COUNTRY_DETAIL_LOADED_iPad11Landscape_light.png" width="816" alt="The list and Bolivia's details side by side on iPad">

The images are the snapshot tests' reference images, so CI fails if the app stops rendering them.

## Code walkthrough
Each part links to the files that show it.

### The two screens
| | Country list | Country detail |
|---|---|---|
| View: owns the view model | [`CountryListView`](Packages/AtlasUI/Sources/AtlasUI/CountryList/Views/CountryListView.swift) | [`CountryDetailView`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/Views/CountryDetailView.swift) |
| Content: draws a state | [`CountryListContent`](Packages/AtlasUI/Sources/AtlasUI/CountryList/Views/CountryListContent.swift) | [`CountryDetailContent`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/Views/CountryDetailContent.swift) |
| View model | [`CountryListViewModel`](Packages/AtlasUI/Sources/AtlasUI/CountryList/ViewModel/CountryListViewModel.swift) | [`CountryDetailViewModel`](Packages/AtlasUI/Sources/AtlasUI/CountryDetail/ViewModel/CountryDetailViewModel.swift) |
| Use case | [`GetCountriesUseCase`](Packages/AtlasDomain/Sources/AtlasDomain/GetCountriesUseCase.swift) | [`GetCountryDetailsUseCase`](Packages/AtlasDomain/Sources/AtlasDomain/GetCountryDetailsUseCase.swift) |
| Repository method | `countries(matching:forceRefresh:)` | `country(code:)` |
| GraphQL query | [`CountriesQuery`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountriesQuery.graphql) | [`CountryQuery`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountryQuery.graphql) |
| Tests | [view model](Packages/AtlasUI/Tests/AtlasUITests/CountryListViewModelTests.swift), [search input](Packages/AtlasUI/Tests/AtlasUITests/CountryListSearchInputTests.swift), [snapshots](AtlasUISnapshotTests/CountryListSnapshotTests.swift) | [view model](Packages/AtlasUI/Tests/AtlasUITests/CountryDetailViewModelTests.swift), [snapshots](AtlasUISnapshotTests/CountryDetailSnapshotTests.swift) |

Both use cases call one [`CountriesRepository`](Packages/AtlasDomain/Sources/AtlasDomain/CountriesRepository.swift), a protocol in AtlasDomain. [`CountriesRepositoryImpl`](Packages/AtlasData/Sources/AtlasData/CountriesRepositoryImpl.swift) in AtlasData implements it over two data sources, [`CountriesRemoteDataSourceImpl`](Packages/AtlasData/Sources/AtlasData/DataSources/CountriesRemoteDataSourceImpl.swift) and [`InMemoryCache`](Packages/AtlasData/Sources/AtlasData/DataSources/InMemoryCache.swift). [`RootView`](Packages/AtlasUI/Sources/AtlasUI/RootView.swift) puts the two screens in a `NavigationSplitView`, and the app's [`AppContainer`](Atlas/AppContainer.swift) builds the repository and the use cases and hands them to it.

### Clean architecture
```
                       Atlas
           ┌─────────────┼──────────────┐
           ▼             ▼              ▼
        AtlasUI ──► AtlasDomain ◄── AtlasData ──► Apollo iOS
           │
           ▼
        AtlasMVI
```

Dependencies point at AtlasDomain, which imports only Foundation and holds the models, the use cases, the repository protocol and `RequestError`. AtlasData implements the protocol, AtlasUI calls the use cases and never imports Apollo, and the app target only composes. Every request takes the same path: view model → use case → repository → data sources.

- **Use cases** hold the rules about the data. `GetCountriesUseCase` sorts by name, because the API sorts by code. `GetCountryDetailsUseCase` only passes the call on.
- **The repository** decides where the data comes from: the cache when it has the answer, the network otherwise. It maps generated types to domain types and caches only successes.
- **Data sources** each talk to one store. The remote one always reaches the network.

Every target builds in the Swift 6 language mode with complete concurrency checking, and a warning fails the build. The details are in [ARCHITECTURE.md](docs/ARCHITECTURE.md), [UI_GUIDELINES.md](docs/UI_GUIDELINES.md) and [DEVELOPMENT.md](docs/DEVELOPMENT.md).

### MVI
Both view models subclass [`MVIViewModel`](Packages/AtlasMVI/Sources/AtlasMVI/MVIViewModel.swift), the base in AtlasMVI, and data moves one way:

1. The view sends an action, such as `.appeared`, `.searchTextChanged` or `.retryTapped`.
2. `reduce(_:_:)` returns the next state. It's the only place the state changes, and it hands each case to a `handle…` method.
3. Slow work starts with `launchEffect`, and its result comes back as an event, such as `.countriesLoaded`, through a second `reduce`. Only the view model can deliver an event, never the view.
4. A one-time UI event goes out as an effect. After a search the list emits `.announce`, and its view posts the result count to VoiceOver.

A view holds its view model as `MVIViewModelProtocol`, which has only `state`, `send` and `effects()`, so it can't call `reduce` or start work itself.

### Observation, @State, async/await and Combine
- **Observation:** view models are `@MainActor @Observable`, and views observe a single `state` value.
- **@State:** each screen's view owns its view model in `@State`. The view model's `init` only stores dependencies; loading starts in `.onAppear`.
- **async/await:** every call from the view model down to Apollo is `async throws`, checked by Swift 6 strict concurrency. A new request cancels the one in flight.
- **Combine:** only for the search field's 300 ms debounce. No API returns a publisher.

### Apollo iOS
Only AtlasData uses Apollo. The repository maps generated types to domain types, so the UI never sees them.

- **Codegen:** [`apollo-codegen-config.json`](apollo-codegen-config.json) generates `internal` Swift into AtlasData. Both queries share the [`CountryBasics`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountryBasics.graphql) fragment. CI runs [`check-codegen.sh`](scripts/check-codegen.sh) against the committed output.
- **Client:** [`makeApolloClient`](Packages/AtlasData/Sources/AtlasData/ApolloClientFactory.swift) sets a 15 s timeout and turns Apollo's cache off with [`NoCacheInterceptor`](Packages/AtlasData/Sources/AtlasData/Interceptors/NoCacheInterceptor.swift).
- **Fetching:** [`ApolloGraphQLClient`](Packages/AtlasData/Sources/AtlasData/ApolloGraphQLClient.swift) fetches with `.networkOnly` and maps every failure to a `RequestError`.
- **Why the cache is off:** Apollo stored the data of responses with GraphQL errors, so a country that failed once read back as "not found". The repository now caches only mapped successes ([tests](Packages/AtlasData/Tests/AtlasDataTests/CountriesRepositoryTests.swift)).

### Testing
124 Swift Testing tests. None touches the network.

- **TDD:** tests come before the code, and each test name starts with its acceptance criterion: `@Test("AC-1.5 no match shows the empty state with the query")`.
- **`sut` and `makeSUT`:** each suite builds the object under test and its doubles in one private `makeSUT(…)`.
- **Unit tests per layer**, each over doubles of the layer below. [`StubURLSession`](Packages/AtlasData/Tests/AtlasDataTests/Doubles/StubURLSession.swift) runs a real `ApolloClient` without the network.
- **Async tests without sleeps:** tests await the task `send` returns, [`SuspendingCountriesRepository`](Packages/AtlasUI/Tests/AtlasUITests/Doubles/SuspendingCountriesRepository.swift) holds each request until the test answers it, and the [`.testTime`](Packages/AtlasMVI/Sources/AtlasMVITesting/TestTime.swift) trait lets a test advance the debounce clock itself.
- **Snapshots:** [`assertSnapshots`](AtlasUISnapshotTests/Helpers/AssertSnapshots.swift), my own helper, renders on iPhone 17 Pro, iPhone Duo folded and unfolded, and iPad in portrait and landscape, in light and dark, plus the largest text size and right-to-left.

To see the other states in the app: search "zzz" for the empty state, open Antarctica for "None" values, and go offline for the error states.

## Build and run
- **Xcode:** 26.0.1 or later. I developed on Xcode 27.1 (27A9269).
- **Deployment target:** iOS 17.0, the first release with the Observation framework.
- **Simulator:** iPhone 17 Pro, iOS 27.0.

Open `Atlas.xcodeproj` and press ⌘R; there's nothing to install. ⌘U runs the tests, and `scripts/lint.sh` runs SwiftLint and SwiftFormat. CI builds and tests every pull request on Xcode 26.0.1 and 27.1. Every other command is in [DEVELOPMENT.md](docs/DEVELOPMENT.md#commands).

## Key decisions
- **Search runs on the server.** The app sends the search term to the API's `name` filter, 300 ms after the user stops typing. That filter is a case-sensitive regex, so `SearchPattern` turns `fr` into `[fF][rR]` to match "France", and escapes characters such as `(` that would break the regex. I didn't download all countries and filter them on the device: the brief asks to debounce queries, and with local filtering there would be no queries to debounce.
- **MVI on a shared base.** The hard cases are about order: a stale search, a retry during a refresh. One `reduce` turns each into a test of one state value. Not a pure reducer returning effects, which splits a screen across two types.
- **One request at a time.** A new load, search, refresh or retry cancels the one in flight, and a cancelled request never touches the state.
- **The detail screen loads by code, from its own query.** Not showing the list's row first, which would tie the screens together.
- **Every layer, even a pass-through.** `GetCountryDetailsUseCase` only forwards, but both screens fetch the same way, and the next rule about the data goes into a use case, not a view model. Added in [PR #17](https://github.com/constzz/countries-ios/pull/17).
- **The repository owns the cache; Apollo's is off.** Only mapped successes are stored, pull-to-refresh skips the cache, and Try Again after a failure always reaches the network. Not Apollo's normalized cache: it stores the data of failed responses, and the repository would have to pass Apollo's cache policies through.
- **Generated code is `internal` to AtlasData**, not a module of its own, so the compiler keeps it out of the UI.
- **Selection per window, in `@SceneStorage`.** `List(selection:)` with `NavigationLink(value:)` lets the split view highlight, push and clear the selection by itself.
- **Snapshots at @1x, within 2/255 per channel.** Liquid Glass over search text varies by 1–2 per channel between runs. @1x took the list's images from 27 MB to under 7 MB ([details](docs/specs/us-1-country-list.md#decisions)).

## Left out
- **A custom EnvironmentValues entry.** Only the root view would read one, and the brief asks for an entry more than one view needs. The custom ViewModifier, `.loadState`, is in, and both screens use it.
- **Diacritic-insensitive search.** The API's regex matches names as written, so "Reunion" misses "Réunion".
- **Localized country and continent names.** Search matches the English names. Currencies stay ISO codes and languages English names, as the API returns them.
- **Git LFS for the snapshot images.** They take 8 MB at @1x, and each re-record adds the changed images to the history. With LFS, a clone without `git lfs` installed gets pointer files instead of images, so the snapshot tests fail, and every CI run downloads the images through LFS. I'd switch once the history grows much larger.

## With more time
- **UI tests**, with accessibility identifiers and a stub repository chosen by launch argument, for navigation, going back, size changes and relaunch, which I check by hand today. Plus a unit test of the 15 s timeout over a transport that never answers.
- **A disk data source** next to the in-memory cache, so a cold start offline still shows the last list. Only the repository would change.
- **A design-system package, then a package per feature.** [`DesignSystem/`](Packages/AtlasUI/Sources/AtlasUI/DesignSystem) (`Palette`, `Typography`, `.loadState`, `ErrorCopy`) goes first, because every feature needs it. Then each screen gets a package with its own string catalog and tests, and the app target composes them in `RootView`. For two screens the extra targets cost more than they save; a third screen or a second team would change that.
- **More snapshots:** iPad multitasking window sizes and the iPhone Duo's rotated postures.

## How I worked
Each story started with a spec in [`docs/specs`](docs/specs): what it delivers, its acceptance criteria and the decisions behind them. Tests came next, then the code. Red commits compile: a failing test runs against a stub instead of breaking the build. Each story merged as its own pull request with a merge commit, so `git log --graph` shows them.

| Story | Spec | Pull request |
|---|---|---|
| US-0 Project setup | [us-0-project-setup.md](docs/specs/us-0-project-setup.md) | [#1](https://github.com/constzz/countries-ios/pull/1) |
| US-1 Country list | [us-1-country-list.md](docs/specs/us-1-country-list.md) | [#2](https://github.com/constzz/countries-ios/pull/2) |
| US-2 Country detail | [us-2-country-detail.md](docs/specs/us-2-country-detail.md) | [#3](https://github.com/constzz/countries-ios/pull/3) |

The later pull requests (#4 to #17) are review and cleanup: design tokens, the rename to Atlas, deterministic timers, the MVI base in its own package, one way to build the system under test, and use cases with data sources.

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
