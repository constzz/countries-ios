# US-2: Country detail

*As a user, I can tap a country to see its name, flag, capital, currencies, languages and continent.*

## Scope
- **Domain:** `CountryDetails`, `Language`, and `CountriesRepository.country(code:)`.
- **Data:** `CountryQuery($code:)` on the `CountryBasics` fragment, the detail mapper, which reuses `CountrySummary(fragment:)`, `null` → `.notFound`, the repository method, and JSON fixtures captured from the live API (Antarctica, Switzerland, an unknown code).
- **UI:** `CountryDetailViewModel` on the shared MVI base, the detail screen as a `List` of `LabeledContent` rows under a flag-and-name header, loading, error and not-found through `.loadState`, selectable list rows that fill the split view's detail column (pushed on compact width), the selection kept in `RootView` and restored with `@SceneStorage`, previews and snapshots of every detail state, and the list snapshots re-recorded for their new disclosure indicators and selection highlight.
- **App:** nothing changes. `AppContainer` already injects the repository, which gains the new method.

**Non-goals:** pull-to-refresh on the detail, currency and language names in the user's language (the API's codes and English names are shown as they are), native language names, subdivisions and phone codes, sharing or copying values, UI tests.

## Acceptance criteria
- [ ] **AC-2.1** Selecting a row shows that country's detail: pushed on compact width, in the detail column on regular width. On compact width each row shows a disclosure indicator.
- [ ] **AC-2.2** The detail shows a header with the flag and the name, then Capital, Currencies, Languages and Continent rows. The name is also the navigation title. Long names and long lists wrap.
- [ ] **AC-2.3** Missing values render as "None": no capital, no currencies (blank entries are dropped) or no languages. Antarctica shows "None" in all three rows.
- [ ] **AC-2.4** The detail shows a loading state until its own query returns; nothing is prefilled from the list. A failure shows an error state with a Try Again button, which repeats the request. Offline has its own message.
- [ ] **AC-2.5** A code the API doesn't know shows a "Country Not Found" state, with no Try Again.
- [ ] **AC-2.6** Snapshots cover the loading, loaded, missing-values, long-name, error, offline and not-found states on every device preset in light and dark, plus accessibility XXXL on iPhone 17 Pro. On regular width the detail fills the detail column beside the list, with the country's row highlighted; on compact width it shows pushed. The list snapshots whose rows changed are re-recorded.
- [ ] **AC-2.7** All detail copy comes from the String Catalog: row labels, "None", loading, error and not-found messages. Currencies and languages use the locale's list format. The localization tests pass, and the loaded state's right-to-left snapshots (iPhone 17 Pro and iPad landscape) are mirrored.
- [ ] **AC-2.8** On regular width the selected row stays highlighted. If a search filters it out, its detail stays visible, and a refresh keeps it. Going back on compact width clears the selection.
- [ ] **AC-2.9** Folding or unfolding the iPhone Duo, and rotating or resizing an iPad window, keep the selected country. After relaunch, each window restores its selection.
- [ ] **AC-2.10** Leaving the detail, or selecting another country, cancels its request in flight. A cancelled request never shows an error, the detail loads again when it reappears, and a stale response never replaces the current state.
- [ ] **AC-2.11** VoiceOver reads the header as the country's name, marked as a heading, without the flag, and each row as its label then its value.

## Screen contract
| State | UI |
|---|---|
| `content` is `.idle` or `.loading` | Full-screen progress with "Loading Country…"; no title |
| `.loaded(details)` | Header: the flag above the name, centered. Rows: Capital, Currencies, Languages, Continent. Title: the name, inline. |
| `.loaded`, a value is missing | That row reads "None" |
| `.failed(.offline)` | "You're Offline", "Connect to the internet and try again.", Try Again |
| `.failed(.notFound)` | "Country Not Found", "This country isn't available. Choose another one.", no button |
| `.failed(other)` | "Couldn't Load Country", "Something went wrong. Try again in a moment.", Try Again |
| Detail column, no selection | "Select a Country" placeholder (from US-1) |

| Interaction | Action | Reduction |
|---|---|---|
| The detail appears (`.task`) | `.appeared` | From `.idle`: `.loading`, fetch the country. Otherwise nothing. |
| The detail disappears (`.onDisappear`) | `.disappeared` | While `.loading`: cancel the fetch, back to `.idle`. Otherwise nothing. |
| Tapping Try Again | `.retryTapped` | From `.failed`: `.loading`, fetch again with the same cache policy |
| A response arrives | `.responseReceived(id, result)` | Ignored unless it answers the latest request. Details → `.loaded`, an error → `.failed`. |

| Interaction | Selection (in `RootView`) |
|---|---|
| Tapping a row | `selection = code`; the detail column shows that country, or it's pushed on compact width |
| Going back on compact width | `selection = nil` |
| A search or refresh without the selected row | Unchanged; the detail stays |
| Folding, unfolding, rotating, resizing | Unchanged |
| Relaunch | Restored from `@SceneStorage`, per window |

## Presentation: MVI
The screen conforms to the shared MVI types in `CountriesUI/Architecture/` (rules in `docs/ARCHITECTURE.md`), the same way the list does. Each type has its own file in `CountryDetail/`.
- **State:** `CountryDetailState: MVIState`: `content` (`idle | loading | loaded(CountryDetails) | failed(CountriesError)`), where not-found is `failed(.notFound)`, and `requestID`, the latest request's id.
- **Actions:** `CountryDetailAction: MVIAction`. The view sends `.appeared`, `.disappeared` and `.retryTapped`; the view model sends `.responseReceived(requestID:, Result<CountryDetails, CountriesError>)`.
- **Effects:** `CountryDetailEffect: MVIEffect` is a caseless enum: the screen has no one-time UI events, so its view doesn't subscribe to `effects()`.
- **View model:** `CountryDetailViewModel` subclasses `MVIViewModel<CountryDetailState, CountryDetailAction, CountryDetailEffect>`. Its `init` stores the country `code` and the repository and does nothing else. `reduce(_:_:)` hands each action to a `handle…` method that reads `current`; the one fetch runs through `launchEffect`, a new one cancels the previous, and the result comes back as `.responseReceived`. A `CancellationError` sends nothing.
- **Views:** `CountryDetailView` owns the view model in `@State`, created in its `init(code:repository:)`, sends `.appeared` from `.task` and `.disappeared` from `.onDisappear`. `CountryDetailContent` draws a given state and sends actions; previews and snapshots render it.
- **One view model per country:** the detail column shows `CountryDetailView(code:repository:).id(code)`, so selecting another country makes a new view with a new view model, and the previous one's `.onDisappear` cancels its request.

### Selection and navigation
- `RootView` owns the selection as `@SceneStorage("selectedCountryCode") var selection: String?`, so each window keeps its own and restores it after relaunch. Neither view model holds it.
- `CountriesSplitView` takes the sidebar and the detail column. The detail column shows the selected country's `CountryDetailView`, or the `SelectCountryPlaceholder` when nothing is selected.
- The list is `List(rows, selection: $selection)` with each row a `NavigationLink(value: country.code)`. The split view highlights the selected row on regular width, pushes the detail on compact width, and clears the selection when the user goes back there.
- `CountryListView` and `CountryListContent` take a `Binding<String?>` for the selection. The list's state and view model don't change.

## Data layer
- **Operation:** `query Country($code: ID!) { country(code: $code) { ...CountryBasics capital currencies languages { code name } } }`. It reads `currencies`, not the joined `currency` string. Codegen output is committed with it, and `scripts/check-codegen.sh` passes.
- **Mapping:** `CountryDetails(country:)` maps the query's country. The summary comes from `CountrySummary(fragment:)`, the same mapper the list uses. A capital that is null or blank becomes `nil`. Blank currency entries are dropped (Antarctica returns `[""]`), and so are languages with a blank name. The API's order is kept: it lists the main currency and language first.
- **Repository:** `country(code:)` fetches with `.cacheFirst`. A `null` country throws `.notFound` and is logged to the `network` category. Transport and GraphQL failures map as in US-1 (`ApolloGraphQLClient`), and the 15 s request timeout applies.
- **Fixtures,** captured from the live API on 2026-10-10: `country-AQ.json` (Antarctica: null capital, `[""]` currencies, no languages), `country-CH.json` (Switzerland: three currencies, three languages) and `country-unknown.json` (`{"country": null}` for `XX`). Codes are case-sensitive: `ch` also returns null, but codes always come from the list.

## Domain types
```swift
public struct Language: Hashable, Sendable {
  public let code: String
  public let name: String
}

public struct CountryDetails: Identifiable, Hashable, Sendable {
  /// The fields the list shows: code, name, flag and continent.
  public let summary: CountrySummary
  public let capital: String?
  /// ISO 4217 codes, main currency first.
  public let currencies: [String]
  public let languages: [Language]
  public var id: String { summary.id }
}

public protocol CountriesRepository: Sendable {
  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary]
  /// The country with `code`. Throws `CountriesError.notFound` when there's none, another
  /// `CountriesError`, or `CancellationError` when the task is cancelled.
  func country(code: String) async throws -> CountryDetails
}
```
`UnavailableCountriesRepository`, the environment entry's default, and the UI test doubles gain the method.

## UI details
- **Header:** the flag emoji at a size that scales with Dynamic Type (`@ScaledMetric` relative to `.largeTitle`), hidden from VoiceOver, above the name in a title font token, centered and wrapping, with the heading trait.
- **Rows:** `LabeledContent` with the label from the catalog and the value as `Text(verbatim:)`, or the catalog's "None". At accessibility sizes `LabeledContent` stacks the value under its label by itself.
- **Values:** a small formatter in `CountryDetail/` turns details into row values: the capital or `nil`, and currencies and language names joined with `.formatted(.list(type: .and))` in the current locale, or `nil` when empty. The view shows `nil` as "None".
- **Error copy:** `ErrorCopy` gains a subject: the list's generic failure stays "Couldn't Load Countries", the detail's is "Couldn't Load Country". Offline copy is shared. `.notFound` gets its own copy and `canRetry == false`, and `.loadState` shows no Try Again for it.
- **Tokens:** new font tokens for the header name and the flag's base text style in `DesignSystem/Typography.swift`. Nothing else is styled by hand.

## Errors and edge cases
| Scenario | Expected | UI state | Recovery |
|---|---|---|---|
| No connection | `.offline` | Offline error | Try Again |
| No response for 15 s, other transport or HTTP failure | `.network` | Error | Try Again |
| GraphQL errors, or `data: null` | `.server` | Error | Try Again |
| `country: null` (unknown code, or a restored code the API dropped) | `.notFound` | Not found | Select another country |
| No capital (AQ, BV, HM, MO, UM) | `capital == nil` | "None" | none needed |
| Currencies `[""]` (AQ) | `[]` | "None" | none needed |
| No languages (AQ) | `[]` | "None" | none needed |
| Eight currencies (ZW) | One list | Wraps | none needed |
| Longest name ("South Georgia and the South Sandwich Islands") | Header wraps; the inline title truncates | Loaded | none needed |
| The user selects another country while one loads | The old request is cancelled | The new country loads | none needed |
| The detail disappears while loading (back on compact width, a size change) | Cancelled, back to `.idle` | Loads again when it reappears | none needed |
| A response to an older request arrives | Ignored by the reducer | Unchanged | none needed |
| A search filters out the selected country | Selection unchanged | The detail stays | none needed |
| A restored selection with no network | `.offline` | Offline error in the detail | Try Again |

## Test plan
| AC | Tests |
|---|---|
| 2.1 | Manual on iPhone 17 Pro and iPad (A16) simulators; the `COUNTRY_DETAIL_*` and re-recorded `COUNTRY_LIST_*` images show the pushed detail and the disclosure indicators on compact width |
| 2.2 | `CountryDetailsTests`: "AC-2.2 details are identified by the country code"; `CountryDetailsMappingTests`: "AC-2.2 maps every field and reuses the summary mapper" (CH fixture); repository: "AC-2.2 fetches the country by code, cache first"; `COUNTRY_DETAIL_LOADED_*`, `COUNTRY_DETAIL_LONG_NAME_*` |
| 2.3 | Mapping: "AC-2.3 Antarctica has no capital, currencies or languages" (AQ fixture), "AC-2.3 a blank capital is no capital"; `CountryDetailValuesTests`: "AC-2.3 missing values are nil"; UI: "AC-2.3 a missing value reads None"; `COUNTRY_DETAIL_MISSING_VALUES_*` |
| 2.4 | View model: "AC-2.4 appearing shows loading, then the details", "AC-2.4 appearing again loads nothing", "AC-2.4 a failure shows the error", "AC-2.4 retry repeats the request"; repository: "AC-2.4 a failure is passed on"; `ErrorCopyTests`: "AC-2.4 the detail's error names a country"; `COUNTRY_DETAIL_LOADING_*`, `_ERROR_*`, `_OFFLINE_*` |
| 2.5 | Repository: "AC-2.5 a null country is not found" (unknown-code fixture); view model: "AC-2.5 an unknown code shows not found"; `ErrorCopyTests`: "AC-2.5 not found has its own copy and no retry"; `COUNTRY_DETAIL_NOT_FOUND_*` |
| 2.6 | `CountryDetailSnapshotTests`: `COUNTRY_DETAIL_LOADING`, `_LOADED`, `_MISSING_VALUES`, `_LONG_NAME`, `_ERROR`, `_OFFLINE`, `_NOT_FOUND`; `CountryListSnapshotTests` re-recorded |
| 2.7 | `LocalizationTests`; `CountryDetailValuesTests`: "AC-2.7 currencies and languages use the locale's list format" (`en_US`); `COUNTRY_DETAIL_LOADED_*_rtl` images |
| 2.8 | Manual on iPad (A16) and iPhone 17 Pro: highlight, search and refresh with a selection, back on compact width; the iPad `COUNTRY_DETAIL_*` images show the highlight |
| 2.9 | Manual: fold and unfold on the iPhone Duo simulator, rotate the iPad, resize an iPad window; relaunch from Xcode after backgrounding the app |
| 2.10 | View model, with the suspending repository: "AC-2.10 disappearing cancels the request and shows no error", "AC-2.10 appearing after disappearing loads again", "AC-2.10 a stale response is ignored" |
| 2.11 | Manual: Accessibility Inspector on the iPhone 17 Pro simulator |

## Decisions
- **The detail loads only from its own query.** It takes the country `code` and nothing else, and shows a loading state until `CountryQuery` answers. Each screen has a query shaped for it, so the detail can gain fields without touching the list's query or models; the `CountryBasics` fragment is what the two share. Rejected: showing the list's summary (flag, name, continent) at once while the rest loads, which couples the detail to the list's data and gives the screen two loading shapes.
- **`CountryDetails` holds a `CountrySummary`** rather than copies of its fields, so both screens describe the shared fields with one type and one mapper. Rejected: flat fields, which duplicate the summary's and let the two mappings drift.
- **One view model per country, through `.id(code)`.** A new selection makes a new view and view model, so no state from the previous country can show, and the previous view's `.onDisappear` cancels its request. Rejected: one long-lived view model with `.task(id: code)` and a `.codeChanged` action, which must reset every field by hand and briefly shows the previous country.
- **Leaving the detail cancels its request and returns it to `.idle`.** Flicking through countries on iPad would otherwise leave a request running for each, and `.idle` makes the next `.appeared` load again, so a size change that removes and re-adds the view never leaves it stuck on loading. Rejected: letting abandoned requests finish and dropping their results.
- **The selection lives in `RootView` as `@SceneStorage`,** the one source for the sidebar and the detail column, kept per window and restored after relaunch. Rejected: selection in the list's view model, which would tie the detail column to the list's state; and `@State` mirrored to `@SceneStorage`, two copies to keep in step.
- **Rows are `NavigationLink(value:)` inside `List(selection:)`,** Apple's pattern for a split-view sidebar: the system highlights the row on regular width, pushes on compact width, clears the selection on back, and adds the disclosure indicator. Rejected: tap gestures that set the selection, which lose the highlight, the indicator and the accessibility traits of a link.
- **A header with the flag and the name, and the name as an inline title.** The header wraps the longest name and gives the flag room; the inline title stays visible when the rows scroll. Rejected: a large title, which truncates long names and leaves the flag no place; and "Flag" and "Name" rows, which make the most important fact look like any other value.
- **Values are shown as the API gives them:** currency codes and English language and continent names, the same as the list. Rejected: currency and language names from `Locale`, which would mix localized names with English ones next to them.
- **Blank values are dropped in the mapper,** so the domain never carries an API quirk and the UI only knows "present" or "missing". Rejected: filtering in the view.
- **Not found offers no Try Again.** Repeating the request won't make the country exist; the user picks another one. Rejected: Try Again on every error, which here would only fail again.
- **The error title names what failed to load,** "Couldn't Load Country" on the detail, while the offline copy is shared. Rejected: one title for both screens, which says "Countries" when a single country failed.
- **AC-2.1, AC-2.8, AC-2.9 and AC-2.11 are checked by hand,** like AC-1.13 and AC-1.14. Navigation, size changes and relaunch need UI tests, listed under "With more time"; the snapshots cover what each state looks like.

Open, settled during the story:
- **Snapshots of a collapsed split view with a selection.** Expected: a `NavigationSplitView` that starts collapsed with a selection shows the detail pushed. Settled by the first detail snapshot on iPhone 17 Pro; if it shows the list instead, compact presets render the detail in a `NavigationStack` under the list's title.
- **`List(selection:)` with the selected row filtered out.** Expected: SwiftUI leaves the binding alone. Settled by the AC-2.8 manual check; if the list clears it, the binding the list gets ignores a `nil` while the selected code isn't among the rows. Going back always happens with the row on screen, so it still clears the selection.
