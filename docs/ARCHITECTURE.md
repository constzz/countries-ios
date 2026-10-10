# Architecture

This document describes the target shape of the app. Each story builds its own slice of it; the story specs in [`specs/`](specs) say which parts exist when.

## Packages

```
                      CountriesApp
           (@main App, AppContainer: composition root)
              │               │               │
              ▼               ▼               ▼
        CountriesUI ──► CountriesDomain ◄── CountriesData ──► Apollo iOS
```

The dependency direction is `UI → Domain ← Data`. The app target is the only place that sees all three.

### CountriesDomain
Foundation only. It defines what the app works with, independent of where the data comes from.
- `Sendable` value models:
  - `CountrySummary`: `code` (also its `id`), `name`, `emoji`, `continent`.
  - `CountryDetails`: the summary fields plus `capital: String?`, `currencies: [String]` and `languages: [Language]`.
  - `Continent` and `Language`.
- `CountriesRepository: Sendable`:
  - `countries(matching:forceRefresh:) async throws -> [CountrySummary]`, sorted by name;
  - `country(code:) async throws -> CountryDetails`.
- `CountriesError: Error, Equatable, Sendable`:

  | Case | When |
  |---|---|
  | `.offline` | `URLError.notConnectedToInternet` or `.networkConnectionLost` |
  | `.network` | any other transport or HTTP failure, including the 15 s request timeout |
  | `.server` | the response has GraphQL errors, or no data |
  | `.notFound` | `country(code:)` returned null |
  | `.decoding`, `.unknown` | everything else |

  Cancellation (`CancellationError`, `URLError.cancelled`) is not a failure: it never becomes an error state. The domain error carries no user-facing text; the copy lives in CountriesUI.

### CountriesData
Implements the repository with Apollo iOS.
- Operations `CountriesQuery($filter:)` and `CountryQuery($code:)`, both built on the fragment `CountryBasics { code name emoji continent { code name } }`. Each screen has its own query, so the detail screen can gain fields without touching the list.
- Apollo's generated code is embedded in this target with `internal` access. No public API can expose a generated type: the compiler rejects it.
- `CountriesRepositoryImpl` is internal and created through one public factory.
- Internal pieces, each unit-tested:
  - mappers, one per GraphQL shape: `CountrySummary(fragment:)`, reused by the detail mapper;
  - `SearchPattern`, which turns the search term into a case-insensitive regex filter for the API;
  - `GraphQLClient`, the seam over `ApolloClient`. Tests replace it with a fake that returns fixture data.
- The Apollo adapter maps transport errors and GraphQL errors to `CountriesError` and logs the real cause.

### CountriesUI
SwiftUI screens and their view models. It imports only CountriesDomain, never Apollo.
- `CountryList/` and `CountryDetail/`, one folder per feature.
- `DesignSystem/`: semantic color, font, spacing and radius tokens, state views, the `.loadState(_:retry:)` modifier and the `\.countriesRepository` environment entry.
- `Resources/Localizable.xcstrings`: all user-facing copy.

### CountriesApp
The `@main` App and `AppContainer`, the composition root. It creates the repository through CountriesData's public factory, with a 15 s request timeout, and injects it into the environment; the factory builds the `ApolloClient`, so Apollo never leaves CountriesData. While the app hosts tests it injects nothing, so no test run touches the network. Startup does nothing else.

## Rules
- Never skip a layer, and map at each boundary: generated types stay in CountriesData, and domain types are what crosses into the UI.
- Protocols are `public`; implementations are `internal`.
- Dependencies come in through `init`. No singletons.
- No use-case layer: view models call the repository protocol directly. At this size, use cases would only pass calls through. They are the first thing to add if business rules appear.
- One UI package with a folder per feature. The split view composes both screens and their shared selection. A package per feature would add a shared design-system package and a catalog and test targets per package, all for two screens.

## Concurrency
- Swift 6 language mode with complete strict concurrency in every target. Isolation is explicit: view models are `@MainActor`, and domain types and the repository are `Sendable`. Packages don't set a default actor isolation, and neither does the app target.
- Everything is async/await. Combine appears in one place only: the search field's input pipe, where it debounces typing. No `@Published`, and no publishers in any API.
- The code compiles with zero warnings on Swift 6.2 (Xcode 26.0.1) and Swift 6.4 (Xcode 27.1).

## Presentation
MVI with one-way data flow: view → action → reducer → new state and effects → view.
- Each screen has an outer view that owns its view model with `@State`, and an inner view that draws a given state and sends actions. Previews and snapshot tests render the inner view.
- A screen's state is one value. Its actions are one enum of everything that can happen, named after what happened: `.appeared`, `.searchTextChanged`, `.retryTapped`, `.refreshRequested`, plus the view model's own, such as `.responseReceived`.
- A pure reducer, `reduce(state, action) -> (state, effects)`, is the only place the state changes. Effects describe work to do: fetch, debounce, announce.
- The view model is `@MainActor @Observable`. It exposes only `state` and `send(_:)`, and runs the effects the reducer returns. Its `init` has no side effects: work starts when the view sends `.appeared` from `.task`, because SwiftUI may create a view's initial `@State` value more than once.
- One request at a time per screen: a new fetch cancels the one in flight, and the reducer ignores any response that doesn't answer the latest request.
- Identity is stable: a country's `code` is its `id` across reloads and filtering.
- No effects framework: effects are a small enum the view model switches over.

## Testing
- Swift Testing throughout. Test names start with the acceptance criterion they cover, e.g. `@Test("AC-1.5 no match shows empty state")`.
- No test touches the network: repository tests use `FakeGraphQLClient` with JSON fixtures, and view-model tests use `MockCountriesRepository`. Test doubles live in test targets.
- Snapshot tests render each screen state on every device preset in light and dark ([UI guidelines](UI_GUIDELINES.md#snapshot-tests)). They live in `CountriesUISnapshotTests`, a test target hosted by the app, because capturing Liquid Glass needs a window scene, which only a host app provides.
- `CountriesApp.xctestplan` runs every test target from one command ([development guide](DEVELOPMENT.md#commands)).

## Logging
`os.Logger`, with a `network` category in CountriesData, called from the Apollo adapter's error mapping. User input such as search terms is logged as `.private`. `print` is banned by lint.
