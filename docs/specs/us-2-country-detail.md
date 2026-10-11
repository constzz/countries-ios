# US-2: Country detail

*As a user, I can tap a country to see its name, flag, capital, currencies, languages and continent.*

## Scope
- **Domain:** `CountryDetails`, `Language`, and `CountriesRepository.country(code:)`.
- **Data:** `CountryQuery($code:)` on the `CountryBasics` fragment, the detail mapper, which reuses `CountrySummary(fragment:)`, `null` → `.notFound`, the repository method, and JSON fixtures captured from the live API (Antarctica, Switzerland, an unknown code).
- **UI:** `CountryDetailViewModel` on the shared MVI base, the detail screen as a `List` of `LabeledContent` rows under a flag-and-name header, loading, error and not-found through `.loadState`, selectable list rows that fill the split view's detail column (pushed on compact width), the selection kept in `RootView` and restored with `@SceneStorage`, `RootView` taking the repository in its `init` in place of the `\.countriesRepository` environment entry, previews and snapshots of every detail state, and the list snapshots re-recorded for their new disclosure indicators and selection highlight.
- **App:** `CountriesApp` passes the container's repository to `RootView(repository:)` instead of the environment. `AppContainer` is unchanged; its repository gains the new method.

**Non-goals:** pull-to-refresh on the detail, currency and language names in the user's language (the API's codes and English names are shown as they are), native language names, subdivisions and phone codes, sharing or copying values, UI tests.

## Acceptance criteria
- [ ] **AC-2.1** Selecting a row shows that country's detail: pushed on compact width, in the detail column on regular width. On compact width each row shows a disclosure indicator.
- [x] **AC-2.2** The detail shows a header with the flag and the name, then Capital, Currencies, Languages and Continent rows. The navigation bar shows the name, inline, only once the header's name has scrolled under it, so the name never shows twice and never lags behind the header. Long names and long lists wrap.
- [x] **AC-2.3** Missing values render as "None": no capital, no currencies (blank entries are dropped) or no languages. Antarctica shows "None" in all three rows.
- [x] **AC-2.4** The detail shows a loading state until its own query returns; nothing is prefilled from the list. A failure shows an error state with a Try Again button, which repeats the request. Offline has its own message.
- [x] **AC-2.5** A code the API doesn't know shows a "Country Not Found" state, with no Try Again.
- [x] **AC-2.6** Snapshots cover the loading, loaded, missing-values, long-name, error, offline and not-found states on every device preset in light and dark, plus accessibility XXXL on iPhone 17 Pro. On regular width the detail fills the detail column beside the list, with the country's row highlighted; on compact width it shows pushed. The list snapshots whose rows changed are re-recorded.
- [x] **AC-2.7** All detail copy comes from the String Catalog: row labels, "None", loading, error and not-found messages. Currencies and languages use the locale's list format. The localization tests pass, and the loaded state's right-to-left snapshots (iPhone 17 Pro and iPad landscape) are mirrored.
- [ ] **AC-2.8** On regular width the selected row stays highlighted. If a search filters it out, its detail stays visible, and a refresh keeps it. Going back on compact width clears the selection.
- [ ] **AC-2.9** Folding or unfolding the iPhone Duo, and rotating or resizing an iPad window, keep the selected country. After relaunch, each window restores its selection.
- [x] **AC-2.10** Leaving the detail, or selecting another country, cancels its request in flight. A cancelled request never shows an error, the detail loads again when it reappears, and a stale response never replaces the current state.
- [ ] **AC-2.11** VoiceOver reads the header as the country's name, marked as a heading, without the flag, and each row as its label then its value.

## Screen contract
| State | UI |
|---|---|
| `content` is `.idle` or `.loading` | Full-screen progress with "Loading Country…"; no title |
| `.loaded(details)` | Header: the flag above the name, centered. Rows: Capital, Currencies, Languages, Continent. No title while the header's name is visible. |
| `.loaded`, `showsTitle` | The name as the inline title |
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
| The header's name scrolls under the bar, or back out | `.headerScrolled(underBar:)` | `showsTitle = underBar` |

| Interaction | Selection (in `RootView`) |
|---|---|
| Tapping a row | `selection = code`; the detail column shows that country, or it's pushed on compact width |
| Going back on compact width | `selection = nil` |
| A search or refresh without the selected row | Unchanged; the detail stays |
| Folding, unfolding, rotating, resizing | Unchanged |
| Relaunch | Restored from `@SceneStorage`, per window |

## Presentation: MVI
The screen conforms to the shared MVI types in `CountriesUI/Architecture/` (rules in `docs/ARCHITECTURE.md`), the same way the list does. Each type has its own file in `CountryDetail/`.
- **State:** `CountryDetailState: MVIState`: `content` (`idle | loading | loaded(CountryDetails) | failed(CountriesError)`), where not-found is `failed(.notFound)`, `requestID`, the latest request's id, and `showsTitle`, whether the header's name is under the navigation bar.
- **Actions:** `CountryDetailAction: MVIAction`. The view sends `.appeared`, `.disappeared`, `.retryTapped` and `.headerScrolled(underBar:)`; the view model sends `.responseReceived(requestID:, Result<CountryDetails, CountriesError>)`.
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
- **Cache:** a response with GraphQL errors is never written to Apollo's cache. `makeApolloClient` builds the client with an interceptor provider whose cache interceptor, `ErrorFreeCacheInterceptor`, skips those responses and otherwise does what Apollo's default one does.
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
The UI test doubles gain the method.

## UI details
- **Header:** the flag emoji at a size that scales with Dynamic Type (`@ScaledMetric` relative to `.largeTitle`), hidden from VoiceOver, above the name in a title font token, centered and wrapping, with the heading trait.
- **Rows:** `LabeledContent` with the label from the catalog and the value as `Text(verbatim:)`, or the catalog's "None". At accessibility sizes `LabeledContent` stacks the value under its label by itself.
- **Values:** `CountryDetailValues` turns details into the text of each row: the capital, or "None" from the catalog; currencies and language names joined with `.formatted(.list(type: .and))` in the view's locale (`\.locale`), or "None" when there are none; and the continent's name.
- **Error copy:** `ErrorCopy` gains a subject: the list's generic failure stays "Couldn't Load Countries", the detail's is "Couldn't Load Country". Offline copy is shared. On the detail, `.notFound` gets its own copy and `canRetry == false`, and `.loadState` shows no Try Again for it. The list never gets `.notFound`; if it did, it would show its generic failure with Try Again, as in US-1.
- **Background:** the detail keeps the system grouped background in every state. An empty `List` draws a plain background whatever its style, so loading and errors would sit on white and the screen would change color when the rows arrive. The list's own background is hidden with `.scrollContentBackground(.hidden)` and `Palette.groupedBackground` is drawn behind it.
- **Tokens:** `Typography.Detail.title` for the header name and `Typography.Detail.flag(size:)` for the flag, whose size is a `@ScaledMetric` relative to `.largeTitle`; `Palette.primaryText` for the name inside the section header, which the system would style as secondary; and `Palette.groupedBackground`. Nothing else is styled by hand.

## Errors and edge cases
| Scenario | Expected | UI state | Recovery |
|---|---|---|---|
| No connection | `.offline` | Offline error | Try Again |
| No response for 15 s, other transport or HTTP failure | `.network` | Error | Try Again |
| GraphQL errors, or `data: null` | `.server`, and nothing is cached | Error | Try Again, which reaches the network |
| `country: null` (unknown code, or a restored code the API dropped) | `.notFound` | Not found | Select another country |
| No capital (AQ, BV, HM, MO, UM) | `capital == nil` | "None" | none needed |
| Currencies `[""]` (AQ) | `[]` | "None" | none needed |
| No languages (AQ) | `[]` | "None" | none needed |
| Eight currencies (ZW) | One list | Wraps | none needed |
| Longest name ("South Georgia and the South Sandwich Islands") | Header wraps; once scrolled away, the inline title truncates | Loaded | none needed |
| The user selects another country while one loads | The old request is cancelled | The new country loads | none needed |
| The detail disappears while loading (back on compact width) | Cancelled, back to `.idle` | Loads again when it reappears | none needed |
| A size change while loading (folding, unfolding, rotating, resizing) | The detail stays; the request keeps running | Loading, then the details | none needed |
| A response to an older request arrives | Ignored by the reducer | Unchanged | none needed |
| A search filters out the selected country | Selection unchanged | The detail stays | none needed |
| A restored selection with no network | `.offline` | Offline error in the detail | Try Again |

## Test plan
| AC | Tests |
|---|---|
| 2.1 | Manual on iPhone 17 Pro and iPad (A16) simulators; the `COUNTRY_DETAIL_*` and re-recorded `COUNTRY_LIST_*` images show the pushed detail and the disclosure indicators on compact width |
| 2.2 | `CountryDetailsTests`: "AC-2.2 details are identified by the country code"; `CountryDetailsMappingTests`: "AC-2.2 maps every field and reuses the summary mapper" (CH fixture); repository: "AC-2.2 fetches the country by code, cache first"; `CountryDetailValuesTests`: "AC-2.2 every row shows its value"; view model: "AC-2.2 the title shows once the header's name is under the bar", "AC-2.2 the title hides when the header's name scrolls back"; manual: scroll the detail at the largest text size; `COUNTRY_DETAIL_LOADED_*`, `COUNTRY_DETAIL_LONG_NAME_*` |
| 2.3 | Mapping: "AC-2.3 Antarctica has no capital, currencies or languages" (AQ fixture), "AC-2.3 blank values are missing values"; `CountryDetailValuesTests`: "AC-2.3 missing values read None"; `COUNTRY_DETAIL_MISSING_VALUES_*` |
| 2.4 | View model: "AC-2.4 appearing shows loading, then the details", "AC-2.4 appearing again loads nothing", "AC-2.4 a failure shows the error", "AC-2.4 retry repeats the request"; repository: "AC-2.4 a failure reaches the caller unchanged", "AC-2.4 a response with GraphQL errors stays out of the cache" (a real `ApolloClient` over `StubURLSession`); `ErrorCopyTests`: "AC-2.4 the detail's error names a country"; `COUNTRY_DETAIL_LOADING_*`, `_ERROR_*`, `_OFFLINE_*` |
| 2.5 | Repository: "AC-2.5 a null country is not found" (unknown-code fixture); view model: "AC-2.5 an unknown code shows not found"; `ErrorCopyTests`: "AC-2.5 not found has its own copy and no retry"; `COUNTRY_DETAIL_NOT_FOUND_*` |
| 2.6 | `CountryDetailSnapshotTests`: `COUNTRY_DETAIL_LOADING`, `_LOADED`, `_MISSING_VALUES`, `_LONG_NAME`, `_ERROR`, `_OFFLINE`, `_NOT_FOUND`; `CountryListSnapshotTests` re-recorded |
| 2.7 | `LocalizationTests`; `CountryDetailValuesTests`: "AC-2.7 currencies and languages use the locale's list format" (`en_US`); `COUNTRY_DETAIL_LOADED_*_rtl` images |
| 2.8 | Manual on iPad (A16) and iPhone 17 Pro: highlight, search and refresh with a selection, back on compact width; the iPad `COUNTRY_DETAIL_*` images show the highlight |
| 2.9 | Manual: fold and unfold on the iPhone Duo simulator, rotate the iPad, resize an iPad window; relaunch from Xcode after backgrounding the app |
| 2.10 | View model, with `SuspendingDetailsRepository`: "AC-2.10 disappearing cancels the request and shows no error", "AC-2.10 appearing after disappearing loads again", "AC-2.10 a stale response is ignored" |
| 2.11 | Manual: Accessibility Inspector on the iPhone 17 Pro simulator |

## Decisions
- **The detail loads only from its own query.** It takes the country `code` and nothing else, and shows a loading state until `CountryQuery` answers. Each screen has a query shaped for it, so the detail can gain fields without touching the list's query or models; the `CountryBasics` fragment is what the two share. Rejected: showing the list's summary (flag, name, continent) at once while the rest loads, which couples the detail to the list's data and gives the screen two loading shapes.
- **`CountryDetails` holds a `CountrySummary`** rather than copies of its fields, so both screens describe the shared fields with one type and one mapper. Rejected: flat fields, which duplicate the summary's and let the two mappings drift.
- **One view model per country, through `.id(code)`.** A new selection makes a new view and view model, so no state from the previous country can show, and the previous view's `.onDisappear` cancels its request. Rejected: one long-lived view model with `.task(id: code)` and a `.codeChanged` action, which must reset every field by hand and briefly shows the previous country.
- **Leaving the detail cancels its request and returns it to `.idle`.** Flicking through countries on iPad would otherwise leave a request running for each, and `.idle` makes the next `.appeared` load again. A size change isn't leaving: measured on iOS 17.0, 26.0 and 27.0 with the split view hosted in a window, collapsing and expanding it (iPad regular and compact width, iPhone Duo folded and unfolded) keeps the detail's view and view model, calls neither `.onDisappear` nor `.task`, and leaves the request running. Rejected: letting abandoned requests finish and dropping their results; and counting appearances in case SwiftUI showed the detail in a new place before leaving the old one, which the measurement shows it doesn't.
- **Responses with GraphQL errors stay out of the cache.** Apollo writes a response's data to its normalized cache even when the response also has errors, and a field that failed arrives as `null`. With `.cacheFirst`, Try Again and every later visit would then read a failed `country` as "Country Not Found", or a failed capital as "None", until relaunch. A cache interceptor that skips such responses is Apollo's documented extension point for this. Rejected: Try Again with `.networkOnly`, which fixes the retry but not the next visit.
- **The selection lives in `RootView` as `@SceneStorage`,** the one source for the sidebar and the detail column, kept per window and restored after relaunch. Rejected: selection in the list's view model, which would tie the detail column to the list's state; and `@State` mirrored to `@SceneStorage`, two copies to keep in step.
- **Rows are `NavigationLink(value:)` inside `List(selection:)`,** Apple's pattern for a split-view sidebar: the system highlights the row on regular width, pushes on compact width, clears the selection on back, and adds the disclosure indicator. Rejected: tap gestures that set the selection, which lose the highlight, the indicator and the accessibility traits of a link.
- **A header with the flag and the name; the bar shows the name only once the header's name has scrolled under it.** That's the pattern of Contacts and the App Store. The header wraps the longest name and gives the flag room, and the bar names the screen once the header is gone. Revised during the story from "the name is also the inline title": SwiftUI hands the navigation bar its title a pass after it draws the content, so a title set when the details arrive showed up a few frames after the header's name, and the name showed twice. Measured on iOS 17, 26 and 27: a `List`'s SwiftUI frame starts at the bar's bottom edge, so the header's name is under the bar when its global `maxY` is above the list's global `minY`. The view sends `.headerScrolled(underBar:)` only when that flips. Rejected: a large title, which truncates long names and leaves the flag no place; the title drawn as a principal toolbar item, which arrives just as late; fading the content in to hide the lag; and "Flag" and "Name" rows, which make the most important fact look like any other value.
- **Values are shown as the API gives them:** currency codes and English language and continent names, the same as the list. Rejected: currency and language names from `Locale`, which would mix localized names with English ones next to them.
- **Blank values are dropped in the mapper,** so the domain never carries an API quirk and the UI only knows "present" or "missing". Rejected: filtering in the view.
- **Not found offers no Try Again.** Repeating the request won't make the country exist; the user picks another one. Rejected: Try Again on every error, which here would only fail again.
- **The error title names what failed to load,** "Couldn't Load Country" on the detail, while the offline copy is shared. Rejected: one title for both screens, which says "Countries" when a single country failed.
- **The detail snapshots show Bolivia, selected in the list beside it.** Its row sits near the top of the sidebar, so the highlight is on screen on every iPad preset, and it has two currencies and three languages. Bolivia joins the list's samples, so the list snapshots gain a row. Rejected: Switzerland, whose row is below the fold on iPad landscape, so the images couldn't show the highlight.
- **No custom EnvironmentValues entry: the repository comes in through `RootView`'s `init`.** Revised during the story. The `\.countriesRepository` entry from US-1 was read only by `RootView`, which passed it on to both screens through `init`, so it moved the repository one level, and its required default, a repository that fails every request, turned a missing injection into an error state at runtime instead of a compile error. The brief asks for an entry only where more than one view genuinely needs it, and two shallow screens have no such value: locale, Dynamic Type and color scheme are SwiftUI's own, and everything else reaches its view through a parameter. Rejected: each screen reading the entry itself, which `init` can't do, so each view would build its view model late and draw an empty first frame.
- **AC-2.1, AC-2.8, AC-2.9 and AC-2.11 are checked by hand,** like AC-1.13 and AC-1.14. Navigation, size changes and relaunch need UI tests, listed under "With more time"; the snapshots cover what each state looks like.

Settled during the story:
- **Snapshots of a collapsed split view with a selection.** A `NavigationSplitView` that starts collapsed with a selection shows the detail pushed, with a back button, so compact presets render the same split view as the others.
- **`List(selection:)` with the selected row filtered out.** SwiftUI leaves the binding alone. Measured on iOS 17.0, 26.0 and 27.0, on regular and compact width, with a split view hosted in a window: filtering the selected row out, emptying the list and bringing the row back never wrote to the binding. So the list takes the selection binding as it is. Rejected: a binding that ignores a `nil` while the selected code isn't among the rows, which would also swallow going back on compact width after a search had filtered the row out on regular width, leaving the user unable to leave the detail.
