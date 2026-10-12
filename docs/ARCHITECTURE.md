# Architecture

This document describes the target shape of the app. Each story builds its own slice of it; the story specs in [`specs/`](specs) say which parts exist when.

## Packages

```
                       Atlas
  (@main AppLauncher, AtlasApp, AppContainer: composition root)
           │             │              │
           ▼             ▼              ▼
        AtlasUI ──► AtlasDomain ◄── AtlasData ──► Apollo iOS
           │
           ▼
        AtlasMVI
```

The dependency direction is `UI → Domain ← Data`, and AtlasUI builds its screens on AtlasMVI, which depends on nothing. The app target is the only place that sees AtlasUI, AtlasDomain and AtlasData together.

A request crosses the layers in one order: view model → use case → repository protocol → repository → data sources.

### AtlasDomain
Foundation only. It defines what the app works with, independent of where the data comes from.
- `Sendable` value models:
  - `CountrySummary`: `code` (also its `id`), `name`, `emoji`, `continent`.
  - `CountryDetails`: a `summary: CountrySummary` plus `capital: String?`, `currencies: [String]` and `languages: [Language]`.
  - `Continent` and `Language`.
- `CountriesRepository: Sendable`:
  - `countries(matching:forceRefresh:) async throws -> [CountrySummary]`, in the API's order;
  - `country(code:) async throws -> CountryDetails`.
- Use cases, what the screens ask of the data: `GetCountriesUseCase`, which sorts the countries by name (the API sorts by code), and `GetCountryDetailsUseCase`. Each is a `Sendable` struct over the repository protocol with one `callAsFunction`, so a view model calls it like a function: `try await getCountries(matching: term, forceRefresh: false)`.
- `RequestError: Error, Equatable, Sendable`, why any request in the app failed. No case belongs to one feature, so a new repository throws it too:

  | Case | When |
  |---|---|
  | `.offline` | `URLError.notConnectedToInternet` or `.networkConnectionLost` |
  | `.network` | any other transport or HTTP failure, including the 15 s request timeout |
  | `.server` | the response has GraphQL errors, or no data |
  | `.notFound` | `country(code:)` returned null |
  | `.decoding`, `.unknown` | everything else |

  Cancellation (`CancellationError`, `URLError.cancelled`) is not a failure: it never becomes an error state. The domain error carries no user-facing text; the copy lives in AtlasUI.

### AtlasData
Implements the repository over two data sources: the API, through Apollo iOS, and memory.
- Operations `CountriesQuery($filter:)` and `CountryQuery($code:)`, both built on the fragment `CountryBasics { code name emoji continent { code name } }`. Each screen has its own query, so the detail screen can gain fields without touching the list.
- Apollo's generated code is embedded in this target with `internal` access. No public API can expose a generated type: the compiler rejects it.
- `CountriesRepositoryImpl` is internal and created through one public factory, `makeCountriesRepository(endpoint:)`, which builds the `ApolloClient` with a 15 s request timeout, the remote data source and the caches.
- `DataSources/`, one data source per storage system:
  - `CountriesRemoteDataSource`, the API. It builds the queries, reaches the network on every call and returns generated types, so the protocol is internal. `CountriesRemoteDataSourceImpl` sends the queries through `GraphQLClient`. No countries for a blank term is a server fault: every country has a name.
  - `InMemoryCache<Key, Value>`, a generic actor that keeps values until the app quits. It never evicts: all the API's data is a few hundred small records.
- The repository decides where data comes from. It returns a cached value when there is one; otherwise it asks the remote data source, maps the result to domain types and caches it. Force refresh skips the cached value. Countries are cached by the trimmed search term, details by code. Only successes are cached, so a failure, including a response with GraphQL errors, is never served again, and Try Again always reaches the network.
- `Interceptors/`: the client keeps Apollo's default interceptors but one: `CountriesInterceptorProvider` swaps in `NoCacheInterceptor`, which never reads or writes Apollo's store. Apollo requires a store, but the repository's cache is the only one. Apollo's would hold a second copy nobody reads, and it would also store the data of a response with GraphQL errors, with each failed field as `null`.
- Internal pieces, each unit-tested:
  - mappers, one per GraphQL shape: `CountrySummaryMapper`, reused by `CountryDetailsMapper`;
  - `SearchPattern`, which turns the search term into a case-insensitive regex filter for the API;
  - `GraphQLClient`, the seam between the remote data source and `ApolloClient`, which always fetches from the network. Tests replace it with a fake that returns fixture data.
- The Apollo adapter maps transport errors and GraphQL errors to `RequestError` and logs the real cause.

### AtlasMVI
The MVI layer every screen is built on, with no knowledge of countries.
- `AtlasMVI`: `MVIState`, `MVIAction`, `MVIEvent`, `MVIEffect`, the `MVIViewModel` base and `MVITime`.
- `AtlasMVITesting`, linked by test targets only: the `.testTime` trait with `TestScheduler` and `TestClock`, and the `eventually` and `first(_:of:)` helpers.
- `AtlasMVITests` test the base on a toy counter view model.

### AtlasUI
SwiftUI screens and their view models. It imports AtlasDomain and AtlasMVI, never Apollo. View models get use cases, never a repository.
- `CountryList/` and `CountryDetail/`, one folder per feature, each grouped the same way:
  - `ViewModel/`: the view model, its state, actions and effects, and the values the state holds;
  - `Views/`: the screen's view, the view that draws its state, and their subviews;
  - `Previews/`: the previews and the sample data they share with the snapshot and unit tests.
- `DesignSystem/`: semantic color, font, spacing and radius tokens, state views, `ErrorCopy` and the `.loadState(_:loadingLabel:retry:)` view modifier.
- `Resources/Localizable.xcstrings`: all user-facing copy.

### Atlas
`AppLauncher`, the `@main` entry point; the `AtlasApp` App; `AppEnvironment`, the settings read from the app's Info.plist; and `AppContainer`, the composition root. `AppEnvironment` holds the API endpoint (`CountriesAPIURL`, set from the `COUNTRIES_API_URL` build setting in `Config/Shared.xcconfig`) and stops the app if it is missing or invalid. `AppContainer` takes an `AppEnvironment`, so it never reads the bundle, creates the repository through AtlasData's public factory and the use cases over it, and `AtlasApp` passes the use cases to `RootView`'s `init`; the factory builds the `ApolloClient`, so Apollo never leaves AtlasData. While the app hosts tests, `AppLauncher` runs `TestHostApp`, one empty window, instead of `AtlasApp`, so no test run builds the app's dependencies or touches the network. `AppContainer` knows nothing about tests, and its dependencies are never optional. Startup does nothing else.

## Rules
- Never skip a layer, and map at each boundary: generated types stay in AtlasData, and domain types are what crosses into the UI.
- Domain protocols are `public`; implementations are `internal`.
- A mapper is a `final class …Mapper` with a `private init()` and one `static func map`, tested on its own. It is never an initializer in an extension on the type it builds, where it would sit among that type's own initializers.
- Dependencies come in through `init`. No singletons.
- A view model calls use cases; a use case calls repository protocols; a repository calls data sources and mappers. No layer reaches past the one below it, even when a use case only passes the call on: every screen gets its data the same way, and a new rule has one place to go. A rule about the data, such as the list's order, belongs in a use case; where the data comes from is the repository's decision.
- One UI package with a folder per feature. The split view composes both screens and their shared selection. A package per feature would add a shared design-system package and a catalog and test targets per package, all for two screens.

## Concurrency
- Swift 6 language mode with complete strict concurrency in every target. Isolation is explicit: view models are `@MainActor`; domain types, use cases, the repository and the data sources are `Sendable`; and the cache is an actor. Packages don't set a default actor isolation, and neither does the app target.
- Everything is async/await. Combine appears only where the search field's input is debounced: the input pipe and `MVITime.debounce(_:for:)`. No `@Published`, and no publishers in any API.
- The code compiles with zero warnings on Swift 6.2 (Xcode 26.0.1) and Swift 6.4 (Xcode 27.1).

## Presentation
MVI with one-way data flow: view → action → `reduce` → new state, plus work and one-time effects → view. Every screen conforms to the shared types in AtlasMVI; there's no third-party framework.
- **Parts.** Each screen has a `…State: MVIState`, a `…Action: MVIAction`, a `…Event: MVIEvent`, a `…Effect: MVIEffect` (a caseless enum when the screen has none) and a `final class …ViewModel: MVIViewModel<…State, …Action, …Event, …Effect>`.
- **One type per file.** Every top-level type has its own file, named after it, in its feature's subfolder for that role. That includes helper values such as `CountriesRequest`.
- **State** is one value with everything the screen shows.
- **Actions** are what the view sends, named after what happened, never as commands: `.appeared`, `.searchTextChanged`, `.retryTapped`, `.refreshRequested`.
- **Events** are what the view model's own work produced, named after the domain event: `.searchSettled`, `.searchProgressDue`, `.countriesLoaded`, `.countryFailedToLoad`. `launchEffect(_:then:)` and `subscribe(to:then:)` deliver them through the base's `receive(_:)`, which is internal to AtlasMVI, so a view can't send one; tests reach it with `@testable import AtlasMVI`. Each kind has its own `reduce`.
- **`reduce(_ current:_ action:)`** is the only place the state changes, and it returns at once. It hands each action to a `handle…` method, and handlers read the `current` argument, never `state`. Async work starts through `launchEffect`, which returns the task so the handler can cancel it; its result comes back as an action through `send`.
- **Effects** are one-time UI events only: today the VoiceOver announcement, later navigation or alerts. The view model calls `emit`, and the view handles them in `.task { for await effect in viewModel.effects() { … } }`. Anything the screen must still show after a redraw is state, not an effect. An effect emitted while no view subscribes is dropped, so the view subscribes before it sends `.appeared`.
- **The base** (`MVIViewModel`, `@MainActor @Observable`) owns `private(set) var state`. `send(_:)` runs `reduce`, assigns the state only when it changed, and returns a task that finishes when the work the action launched has, so `.refreshable` and tests can await it.
- **Time comes from the base.** A view model debounces with `time.debounce(_:for:)` and waits with `time.wait(for:)`, whose deadline is fixed when it's called. `time` is `MVITime.current`, a task-local the base reads when the view model is created: `DispatchQueue.main` and `ContinuousClock` in the app. No view model takes a scheduler or a clock in its `init`.
- **The view model prepares the text.** State and effects carry strings ready to show: the detail's rows are `CountryDetailValues`, which `CountryDetailViewModel` builds in its locale, and a search's announcement is the sentence VoiceOver reads. Views lay out text; they don't format domain values.
- **Views** use only `state`, `send(_:)` and `effects()`. Each screen has an outer view that owns its view model with `@State` and handles its effects, and an inner view that draws a given state and sends actions. Previews and snapshot tests render the inner view.
- **No work in `init`.** A view model's `init` only stores its dependencies: SwiftUI builds a view's initial `@State` value every time it creates the view and discards all but the first. Pipes are built on first use, and work starts when the view sends `.appeared` from `.onAppear`.
- **One request at a time** per screen: a new fetch cancels the one in flight, and a response to a cancelled fetch is never applied.
- **Stable identity:** a country's `code` is its `id` across reloads and filtering.
- **Tests** drive a view model through `send`, await `send(_:).value`, replace its dependencies with test doubles, and check the state, the calls the doubles recorded and the effects. `MVIViewModelTests` covers the base on a toy view model.

## Testing
- Swift Testing throughout. Test names start with the acceptance criterion they cover, e.g. `@Test("AC-1.5 no match shows empty state")`. Tests of the shared architecture types cover no story, so their names carry no AC.
- No test touches the network, and each layer is tested against doubles of the one below it: use cases over `MockCountriesRepository`; the repository over `FakeCountriesRemoteDataSource` and real caches; the remote data source over `FakeGraphQLClient` with JSON fixtures; and the view models over real use cases, with `MockCountriesRepository`, `SuspendingCountriesRepository` and `SuspendingDetailsRepository` underneath. The Apollo client tests, and two repository tests of the whole data stack, run a real `ApolloClient` over `StubURLSession`. Test doubles live in test targets.
- No test waits out a timer. A suite whose view models use time adds the `.testTime` trait, which gives each test its own `TestScheduler` and `TestClock` as `MVITime.current`. The test moves them through `TestTime.scheduler` and `TestTime.clock`; nothing else moves them.
- Snapshot tests render each screen state on every device preset in light and dark, and placeholder states on iPhone 17 Pro in light ([UI guidelines](UI_GUIDELINES.md#snapshot-tests)). They live in `AtlasUISnapshotTests`, a test target hosted by the app, because capturing Liquid Glass needs a window scene, which only a host app provides.
- `Atlas.xctestplan` runs every test target from one command ([development guide](DEVELOPMENT.md#commands)).

## Logging
`os.Logger`, with a `network` category in AtlasData, called wherever a request fails: the Apollo adapter's error mapping, the remote data source and the repository. User input such as search terms is logged as `.private`. `print` is banned by lint.
