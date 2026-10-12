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
           │             │              │
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

A view reads `state`, calls `send` and listens to `effects()`. That's all it can do.

### Observation, @State, async/await and Combine
- **Observation.** `MVIViewModel` is `@MainActor @Observable`. Its bookkeeping is `@ObservationIgnored`, so `state` is the only property views observe, and `state` is assigned only when `reduce` returns a different value: an action that changes nothing redraws nothing.
- **@State.** Each screen's view owns its view model in `@State`. SwiftUI keeps the first instance but runs the view's `init` on every parent redraw, so a view model's `init` only stores its dependencies, and loading starts from `.onAppear`. `RootView` keeps the selected country code in `@SceneStorage` and hands it to the list as a `@Binding`. The detail view gets `.id(code)`, so each country gets a new view model.
- **async/await.** Everything below the view model is `async throws`: the use cases, the repository protocol, the remote data source and Apollo's `fetch`. The cache is an actor, and the protocols and use cases are `Sendable`. `launchEffect` runs the work in a `Task` the view model can cancel, and a cancelled task never reaches `reduce`. `send` returns a task that ends when the work it started has, so `.refreshable { await send(.refreshRequested).value }` keeps the refresh spinner up until the answer arrives, and tests await the same task.
- **Combine** is used only for the search field's input. Keystrokes go into a `PassthroughSubject`, are trimmed, debounced for 300 ms and deduplicated, and come back as a `.searchSettled` event through the base's `subscribe(to:then:)`. The debounce runs on the scheduler in [`MVITime`](Packages/AtlasMVI/Sources/AtlasMVI/MVITime.swift), a task-local the tests replace. No API in the app returns a publisher.

### Apollo iOS
Apollo is used only inside AtlasData. The remote data source returns generated types, and the repository maps them to domain types, so nothing in AtlasDomain or AtlasUI sees one.

- **Codegen.** The schema is downloaded by introspection into [`schema.graphqls`](Packages/AtlasData/Sources/AtlasData/GraphQL/schema.graphqls). Both queries spread the [`CountryBasics`](Packages/AtlasData/Sources/AtlasData/GraphQL/CountryBasics.graphql) fragment, so both screens map a country with the same code. [`apollo-codegen-config.json`](apollo-codegen-config.json) writes the Swift into AtlasData as `internal`. The output is committed, and CI runs [`check-codegen.sh`](scripts/check-codegen.sh) to check that codegen still reproduces it.
- **The client.** [`makeApolloClient`](Packages/AtlasData/Sources/AtlasData/ApolloClientFactory.swift) sets a 15 s timeout instead of URLSession's 60 s, and puts [`NoCacheInterceptor`](Packages/AtlasData/Sources/AtlasData/Interceptors/NoCacheInterceptor.swift) in the request chain, so Apollo's store stays empty.
- **Fetching.** [`ApolloGraphQLClient`](Packages/AtlasData/Sources/AtlasData/ApolloGraphQLClient.swift) implements the `GraphQLClient` protocol and is the only type that fetches through `ApolloClient`. It fetches with `.networkOnly` and turns every failure into a `RequestError`: no connection is `.offline`, any other transport or HTTP failure `.network`, a parse failure `.decoding`, and GraphQL errors `.server`. The cause goes to `os.Logger`; the screen only gets the case.
- **Queries.** `CountriesRemoteDataSourceImpl` builds the `GraphQLNullable` filter from [`SearchPattern`](Packages/AtlasData/Sources/AtlasData/SearchPattern.swift), and the repository maps the results with [`CountrySummaryMapper`](Packages/AtlasData/Sources/AtlasData/CountrySummaryMapper.swift) and [`CountryDetailsMapper`](Packages/AtlasData/Sources/AtlasData/CountryDetailsMapper.swift).
- **Why Apollo's cache is off.** While testing retry I found that Apollo caches the data of a response that also has GraphQL errors, with each failed field stored as `null`. Read back with `.cacheFirst`, a country that had failed to load showed as "not found" until relaunch. Now the repository caches mapped successes itself, and two [repository tests](Packages/AtlasData/Tests/AtlasDataTests/CountriesRepositoryTests.swift) run a real `ApolloClient` over a stubbed `URLSession` to check this end to end.

### Testing
123 `@Test` functions, all Swift Testing, run by one test plan. None touches the network.

- **Tests first.** Each story's spec numbers its acceptance criteria, and a test that checks one starts with its number: `@Test("AC-1.5 no match shows the empty state with the query")`. `grep -rn "AC-1\." Packages AtlasUISnapshotTests` lists everything that checks US-1. The tests came before the code, story by story ([How I worked](#how-i-worked)).
- **`sut` and `makeSUT`.** The object under test is `sut`, built by a private `makeSUT(…)` at the end of the suite, which also returns the doubles a test checks: `let (sut, repository) = makeSUT(result: .success(rows))`.
- **Swift Testing.** Suites are structs, checks are `#expect` and `#require`, and traits do the setup: [`.testTime`](Packages/AtlasMVI/Sources/AtlasMVITesting/TestTime.swift) gives each test its own scheduler and clock, and `.enabled(if:)` skips snapshots anywhere but the reference simulator.
- **Unit tests, layer by layer**, each against doubles of the layer below:
  - Domain: the use cases over `MockCountriesRepository`.
  - Data: the mappers against JSON fixtures, `SearchPattern`, error mapping, the remote data source over `FakeGraphQLClient`, and the repository over `FakeCountriesRemoteDataSource` and a real cache. The Apollo client tests, and two repository tests of the whole data stack, run a real `ApolloClient` over [`StubURLSession`](Packages/AtlasData/Tests/AtlasDataTests/Doubles/StubURLSession.swift).
  - View models: driven through `send`, with real use cases over a repository double.
  - AtlasMVI: the base itself, over a small counter view model.
- **Async tests that don't sleep.**
  - `await sut.send(.appeared).value` waits for exactly the work that action started.
  - [`SuspendingCountriesRepository`](Packages/AtlasUI/Tests/AtlasUITests/Doubles/SuspendingCountriesRepository.swift), an actor, holds each request until the test answers it. A test can answer an older search after a newer one and check that the stale answer never shows.
  - Under `.testTime`, time moves only when the test advances it. The debounce test types three letters 200 ms apart, advances 299 ms and checks that nothing has settled, then 1 ms more and checks that "ger" has.
  - Where there's no task to await, [`eventually`](Packages/AtlasMVI/Sources/AtlasMVITesting/Eventually.swift) polls a condition a bounded number of times.
- **Snapshots on iPhone, iPhone Duo and iPad.** [`assertSnapshots`](AtlasUISnapshotTests/Helpers/AssertSnapshots.swift), a small helper I wrote instead of adding a dependency, renders on five [presets](AtlasUISnapshotTests/Helpers/SnapshotPreset.swift) measured on the simulators: iPhone 17 Pro, iPhone Duo folded and unfolded, and iPad 11-inch in portrait and landscape, each in light and dark. Content states render on all five; loading, empty and error states on iPhone only. Every state also renders at the largest accessibility text size, and the loaded screens right-to-left. The tests draw the `…Content` views from a fixed state, so nothing loads or waits. They run hosted by the app, because capturing Liquid Glass needs a window scene, and compare only on Xcode 27.1 with the iOS 27.0 simulator.

To see each state yourself: the [snapshot images](AtlasUISnapshotTests/snapshots), the SwiftUI previews, or the app. Search "zzz" for the empty state, open Antarctica for "None" values, and turn the Mac's network off, or set Network Link Conditioner to 100% loss, for the offline and error states.

## Build and run
- **Xcode:** 26.0.1 or later. I developed on Xcode 27.1 (27A9269).
- **Deployment target:** iOS 17.0, the first release with the Observation framework.
- **Simulator:** iPhone 17 Pro, iOS 27.0.

Open `Atlas.xcodeproj` and press ⌘R. There's nothing to install: the generated GraphQL code is committed, and Apollo iOS 2.4.0 is the only dependency, pinned to that exact version.

### Tested with
| Xcode | Simulator | Local | CI |
|---|---|---|---|
| 27.1 | iPhone 17 Pro, iOS 27.0 | ✓ (with snapshots) | every pull request and push to main; snapshots in their own workflow |
| 27.1 | iPhone 15 Pro, iOS 17.0 | ✓ | not run: no CI image has the iOS 17.0 runtime |
| 26.0.1 | iPhone 17 Pro, iOS 26.0 | ✓ | every pull request and push to main |

### Commands
| Task | Command |
|---|---|
| All tests | `xcodebuild test -scheme Atlas -testPlan Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' -collect-test-diagnostics never` |
| Test matrix (Xcode 26 and 27) | `scripts/test-matrix.sh` |
| Lint | `scripts/lint.sh` (needs `brew install swiftlint swiftformat`) |
| Record snapshots | the `RecordSnapshots` test plan ([details](docs/DEVELOPMENT.md#snapshot-tests)) |
| Codegen | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#codegen) |

To check right-to-left layout or long text, choose Edit Scheme → Run → Options → App Language → Right-to-Left Pseudolanguage or Double-Length Pseudolanguage.

## Key decisions
- **Search on the server**, at most one query per 300 ms pause. `SearchPattern` makes the API's case-sensitive regex match any case (`fr` → `[fF][rR]`) and escapes metacharacters. Not filtering on the device: typing would send no queries, so the debounce would do nothing.
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
