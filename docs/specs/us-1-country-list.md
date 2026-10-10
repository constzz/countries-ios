# US-1: Country list

*As a user, I can browse every country with its flag, name and continent, and search by name, so I can find a country quickly.*

## Scope
- **Domain:** `CountrySummary`, `Continent`, `CountriesError`, and `CountriesRepository.countries(matching:forceRefresh:)`.
- **Data:** `CountriesQuery($filter:)` on the `CountryBasics` fragment, `SearchPattern`, the `GraphQLClient` seam with its Apollo adapter and error mapping, the summary mapper, the repository and its public factory, and the `network` logger.
- **UI:** `CountryListViewModel`, the list screen with `.searchable` and `.refreshable` as the sidebar of a `NavigationSplitView` whose detail column shows a "Select a Country" placeholder, the shared state views, the `.loadState(_:retry:)` modifier, the `\.countriesRepository` environment entry, previews and snapshots of every list state. The US-0 placeholder root screen and its snapshots are replaced.
- **App:** `AppContainer` builds the `ApolloClient` with a 15 s request timeout and injects the repository.

**Non-goals:** selecting a row and the country detail (US-2), diacritic-insensitive search ("Reunion" doesn't find "Réunion"), localized country names, persistence beyond Apollo's in-memory cache, UI tests.

## Acceptance criteria
- [ ] **AC-1.1** The list shows every country with its flag, name and continent, sorted by name.
- [ ] **AC-1.2** Typing issues at most one query per 300 ms pause, and a term that is unchanged after trimming issues none.
- [ ] **AC-1.3** Search is case-insensitive, and special characters such as `(` don't produce an error. A blank term lists every country.
- [ ] **AC-1.4** The first load shows a full-screen loading state. Later searches and refreshes keep the current rows visible: a search shows a progress indicator in the toolbar, and a refresh shows the system refresh control.
- [ ] **AC-1.5** A search with no match shows an empty state that names the query.
- [ ] **AC-1.6** A failure shows an error state with a Try Again button, which repeats the last request. Offline has its own message.
- [ ] **AC-1.7** Rows keep their identity, the country code, across refresh and filtering.
- [ ] **AC-1.8** Pull-to-refresh fetches fresh data from the network, bypassing the cache.
- [ ] **AC-1.9** Snapshots cover the loading, loaded, searching, empty, error and offline states on every device preset in light and dark, plus accessibility XXXL on iPhone 17 Pro. On regular width (iPad, unfolded iPhone Duo where the system gives two columns) the list sits beside the "Select a Country" placeholder.
- [ ] **AC-1.10** All list copy comes from the String Catalog: title, search prompt, loading, error and placeholder messages, the Try Again button and the VoiceOver announcements. The localization tests pass, and the loaded state's right-to-left snapshots (iPhone 17 Pro and iPad landscape) are mirrored.
- [ ] **AC-1.11** Starting a load, search, refresh or retry cancels the request in flight, and a stale response never replaces newer results. A cancelled request never shows an error.
- [ ] **AC-1.12** After each search, VoiceOver announces the number of results, with plural variants, or that there are none.
- [ ] **AC-1.13** A request with no response for 15 s ends in the error state.
- [ ] **AC-1.14** VoiceOver reads each row as one element, name then continent, without reading the flag.

## Screen contract
| State | UI |
|---|---|
| `idle`, `loading` | Full-screen progress with "Loading Countries…" |
| `loaded(rows)` | One row per country: flag, name, and the continent below it in secondary text. Long names wrap. |
| `loaded` while a search runs | The rows stay; a progress indicator in the toolbar |
| `loaded` while refreshing | The rows stay; the system refresh control |
| `empty(query:)` | `ContentUnavailableView.search(text: query)` |
| `failed(.offline)` | "You're Offline", "Connect to the internet and try again.", Try Again |
| `failed(other)` | "Couldn't Load Countries", "Something went wrong. Try again in a moment.", Try Again |
| Detail column, regular width | "Select a Country" placeholder |

| Interaction | Event | Effect |
|---|---|---|
| The screen appears (`.task`) | `onAppear()` | The first time, loads every country (`idle → loading`). Later, nothing. |
| Typing in the search field | `searchTextChanged(_:)` | Trim, debounce 300 ms, drop duplicates, then search the term |
| Clearing the search field | `searchTextChanged("")` | Same pipe; a blank term lists every country |
| Pull to refresh | `refreshRequested()` | Re-runs the current term from the network |
| Tapping Try Again | `retryTapped()` | Repeats the last request: same term, same cache policy |
| A search finishes | | VoiceOver announces the result count |

Load, search, refresh and retry share one task: starting one cancels the one in flight. Full-screen loading shows only when there are no rows to keep (the first load, or after a failure).

## Data layer
- **Operation:** `query Countries($filter: CountryFilterInput) { countries(filter: $filter) { ...CountryBasics } }`. A blank term sends no filter.
- **`SearchPattern`** (internal, pure) turns a term into a regex for the `name` filter: trim whitespace (blank means no filter), escape `\ ^ $ . | ? * + ( ) [ ] { }`, and wrap each cased letter as `[xX]`. Letters whose case mapping isn't one-to-one, such as `ß`, pass through unchanged. The API's regex is case-sensitive, so this makes the search case-insensitive, and an unescaped `(` would return a server error.
- **Mapping:** `CountrySummary(fragment: CountryBasics)` maps code, name, emoji and continent (code and name). One mapper per GraphQL shape; US-2 reuses it.
- **Repository:** `countries(matching:forceRefresh:)` fetches with `.cacheFirst`, or `.networkOnly` when `forceRefresh` is true, maps every country and sorts by name with `localizedStandardCompare`.
- **`GraphQLClient`** (internal protocol): `fetch<Q: GraphQLQuery>(_:cachePolicy:) async throws -> Q.Data`. The Apollo adapter maps a response with GraphQL errors or no data to `.server`, and transport failures as below. Tests use `FakeGraphQLClient`, which returns `Q.Data` built from JSON fixtures captured from the live API.
- **Error mapping** (a pure helper): `URLError.notConnectedToInternet` and `.networkConnectionLost` → `.offline`; `.timedOut` and other transport or HTTP failures → `.network`; `CancellationError` and `URLError.cancelled` → rethrown as `CancellationError`; anything else → `.unknown`. Each mapped failure is logged to the `network` category with its real cause; the search term is `.private`.
- **Factory:** CountriesData exposes one public factory that returns `any CountriesRepository`; the implementation stays internal.

## Domain types
```swift
public struct Continent: Hashable, Sendable {
  public let code: String
  public let name: String
}

public struct CountrySummary: Identifiable, Hashable, Sendable {
  public let code: String
  public let name: String
  public let emoji: String
  public let continent: Continent
  public var id: String { code }
}

public enum CountriesError: Error, Equatable, Sendable {
  case offline, network, server, notFound, decoding, unknown
}

public protocol CountriesRepository: Sendable {
  /// Countries whose name matches `term`, sorted by name. A blank term returns every country.
  /// Throws `CountriesError`, or `CancellationError` when the task is cancelled.
  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary]
}
```
`.notFound` is unused until US-2. The UI's state is `idle | loading | loaded([CountrySummary]) | empty(query: String) | failed(CountriesError)`, plus `isUpdating` while a search runs over visible rows.

## Errors and edge cases
| Scenario | Expected | UI state | Recovery |
|---|---|---|---|
| No connection | `.offline` | Offline error | Try Again |
| No response for 15 s | `.network` | Error | Try Again |
| Other transport or HTTP failure | `.network` | Error | Try Again |
| GraphQL errors, or `data: null` | `.server` | Error | Try Again |
| A newer request starts | `CancellationError` | Unchanged; the newest request decides | none needed |
| Term `(` or `C++` | Escaped, sent as a regex | Results or empty | none needed |
| Blank or whitespace-only term | No filter | Every country | none needed |
| Term unchanged after trimming | No request | Unchanged | none needed |
| No match | `[]` | `empty(query:)` | Edit the search |
| A search fails while rows are shown | Error | Error replaces the rows | Try Again re-runs the term |
| A refresh fails | Error | Error replaces the rows | Try Again refreshes again |
| Unaccented input ("Reunion") | No match | `empty(query:)` | Left out (README) |
| Longest name ("South Georgia and the South Sandwich Islands") | Wraps | Loaded | none needed |

## Test plan
| AC | Tests |
|---|---|
| 1.1 | `CountrySummaryMappingTests`: "AC-1.1 maps the fragment to a summary"; repository: "AC-1.1 returns every country sorted by name" (250-country fixture); VM: "AC-1.1 load shows the loaded rows" |
| 1.2 | VM, short injected interval and recorded mock calls: "AC-1.2 typing searches once after a pause", "AC-1.2 an unchanged term issues no search" |
| 1.3 | `SearchPatternTests`: "AC-1.3 letters match either case", "AC-1.3 regex metacharacters are escaped", "AC-1.3 a blank term means no filter"; repository: "AC-1.3 sends the pattern as a name regex filter" |
| 1.4 | VM: "AC-1.4 first load shows loading", "AC-1.4 a search keeps rows visible while updating", "AC-1.4 a refresh keeps rows visible" |
| 1.5 | VM: "AC-1.5 no match shows the empty state with the query" |
| 1.6 | VM: "AC-1.6 failure shows the error", "AC-1.6 retry repeats the last request"; error mapping: "AC-1.6 not connected maps to offline" and one test per row of the mapping; UI: "AC-1.6 offline has its own message" |
| 1.7 | VM: "AC-1.7 rows keep their codes across refresh and filtering" |
| 1.8 | Repository: "AC-1.8 force refresh fetches network-only"; VM: "AC-1.8 refresh requests a forced refresh" |
| 1.9 | `CountryListSnapshotTests`: `COUNTRY_LIST_LOADING`, `_LOADED`, `_SEARCHING`, `_EMPTY`, `_ERROR`, `_OFFLINE` |
| 1.10 | `LocalizationTests` (every key current, commented and translated); "AC-1.10 error copy comes from the catalog"; `COUNTRY_LIST_LOADED_*_rtl` images |
| 1.11 | VM, with a mock repository that suspends until released: "AC-1.11 a new search cancels the one in flight", "AC-1.11 a stale response never replaces newer results", "AC-1.11 a cancelled request shows no error" |
| 1.12 | "AC-1.12 the announcement counts results", "AC-1.12 no results is announced" |
| 1.13 | Manual: Network Link Conditioner at 100% loss, the error state appears after about 15 s |
| 1.14 | Manual: Accessibility Inspector on the iPhone 17 Pro simulator |

## Decisions
- **The empty search state is the system's `ContentUnavailableView.search(text:)`.** It names the query, and iOS localizes its copy in every language it supports, so it needs no catalog entry. Rejected: our own "No countries match “…”" sentence in a hand-built `ContentUnavailableView`, which rebuilds a system component.
- **Snapshots render the split view with the list's inner view fed a fixed state.** No snapshot loads data or depends on timing. Rejected: the full screen with a stub repository, which would rely on the helper's few layout passes to settle.
- **Sorting is part of the repository contract.** The API sorts by code; every caller wants names. Rejected: sorting in the view model, which lets an API quirk leak into the UI.
- **Retry repeats the last request with its cache policy,** so a failed refresh retries from the network. Rejected: retry always reading through the cache, which could bring back the data the refresh meant to replace.
- **A failure replaces the rows with the error state.** One state at a time keeps the screen contract small. Rejected: stale rows under an error banner, a sixth state for a rare case.
- **VoiceOver announces after searches only,** not after the first load or a refresh, where the content the user asked for is already on screen.
- **AC-1.13 and AC-1.14 are checked by hand.** Testing them automatically needs a stalled network transport and UI tests; both are listed under "With more time".

Open, settled during the story:
- **Isolation of the Combine `sink`** under Swift 6 on both compilers: settled by the first task, a failing VM test for AC-1.2, with whichever approach compiles warning-free on Xcode 26.0.1 and 27.1.
- **How Apollo 2.4.0 wraps a `URLError`:** settled by reading its transport errors while writing the error-mapping tests, so the adapter unwraps exactly what Apollo throws.
