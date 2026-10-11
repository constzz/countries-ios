# US-2: Country detail

> Delivered in [PR #3](https://github.com/constzz/countries-ios/pull/3) on 2026-10-11. The spec isn't updated after merge: the code and the guides in `docs/` describe the app as it is now.
> **Changed since:** the detail keeps no request id: a cancelled fetch sends nothing back, so `.responseReceived` carries only the result, and a response to an older request never reaches the reducer; `showsTitle` is `isHeaderUnderBar` (PR #13).

*As a user, I can tap a country to see its name, flag, capital, currencies, languages and continent.*

## Scope
- **Domain:** country details with their languages, and the repository's method that fetches one country by code.
- **Data:** the country query, which shares the list's fragment and summary mapper, the detail mapper, not-found for an unknown code, and an Apollo cache that never stores a response with GraphQL errors.
- **UI:** the detail screen on the shared MVI base, with loading, error and not-found states; selectable list rows that fill the split view's detail column, or push the detail on compact width; the selection kept per window and restored after relaunch; the repository passed to `RootView` through its `init` in place of the `\.countriesRepository` environment entry; previews and snapshots of every detail state, and the list snapshots re-recorded for their disclosure indicators and selection highlight.
- **App:** `AtlasApp` passes the container's repository to `RootView(repository:)` instead of the environment.

**Non-goals:** pull-to-refresh on the detail, currency and language names in the user's language (the API's codes and English names are shown as they are), native language names, subdivisions and phone codes, sharing or copying values, UI tests.

## Acceptance criteria
- [ ] **AC-2.1** Selecting a row shows that country's detail: pushed on compact width, in the detail column on regular width. On compact width each row shows a disclosure indicator.
- [x] **AC-2.2** The detail shows a header with the flag and the name, then Capital, Currencies, Languages and Continent rows. The navigation bar shows the name, inline, only once the header's name has scrolled under it, so the name never shows twice and never lags behind the header. Long names and long lists wrap.
- [x] **AC-2.3** Missing values render as "None": no capital, no currencies (blank entries are dropped) or no languages. Antarctica shows "None" in all three rows.
- [x] **AC-2.4** The detail shows a loading state until its own query returns; nothing is prefilled from the list. A failure shows an error state with a Try Again button, which repeats the request. Offline has its own message.
- [x] **AC-2.5** A code the API doesn't know shows a "Country Not Found" state, with no Try Again.
- [x] **AC-2.6** Snapshots cover the loading, loaded, missing-values, long-name, error, offline and not-found states. Loaded, missing values and long name render on every device preset in light and dark; loading, error, offline and not found render on iPhone 17 Pro in light. Every state also renders at accessibility XXXL on iPhone 17 Pro. On regular width the detail fills the detail column beside the list, with the country's row highlighted; on compact width it shows pushed. The list snapshots whose rows changed are re-recorded.
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

## Verification
Every automated test names the AC it covers, as in `@Test("AC-2.5 an unknown code shows not found")`, so `grep -rn "AC-2\." Packages AtlasUISnapshotTests` lists them. Checked by hand:

| AC | How |
|---|---|
| 2.1 | On the iPhone 17 Pro and iPad (A16) simulators; the `COUNTRY_DETAIL_*` and re-recorded `COUNTRY_LIST_*` images show the pushed detail and the disclosure indicators on compact width |
| 2.2 | Scroll the detail at the largest text size: the name shows in the bar only once the header's name is under it |
| 2.8 | On iPad (A16) and iPhone 17 Pro: highlight, search and refresh with a selection, back on compact width; the iPad `COUNTRY_DETAIL_*` images show the highlight |
| 2.9 | Fold and unfold on the iPhone Duo simulator, rotate the iPad, resize an iPad window; relaunch from Xcode after backgrounding the app |
| 2.11 | Accessibility Inspector on the iPhone 17 Pro simulator |

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
- **The detail keeps the grouped background in every state.** An empty `List` draws a plain background whatever its style, so loading and errors would sit on white and the screen would change color when the rows arrive. The list hides its own background and `Palette.groupedBackground` is drawn behind it.
- **The detail snapshots show Bolivia, selected in the list beside it.** Its row sits near the top of the sidebar, so the highlight is on screen on every iPad preset, and it has two currencies and three languages. Bolivia joins the list's samples, so the list snapshots gain a row. Rejected: Switzerland, whose row is below the fold on iPad landscape, so the images couldn't show the highlight.
- **Placeholder states render on iPhone 17 Pro in light, plus accessibility XXXL; this applies to the list's states too.** Loading, empty, error, offline and not found center a system `ProgressView` or `ContentUnavailableView`. Other presets and dark mode show the same view in a different place, and the copy is checked by `ErrorCopyTests` and `LocalizationTests`. The accessibility image still catches long copy wrapping. This took the reference images from 147 to 75. Rejected: every state on every preset in light and dark, where most of the 147 images re-checked system placeholders, slowed the snapshot check and buried the images worth reviewing.
- **No custom EnvironmentValues entry: the repository comes in through `RootView`'s `init`.** Revised during the story. The `\.countriesRepository` entry from US-1 was read only by `RootView`, which passed it on to both screens through `init`, so it moved the repository one level, and its required default, a repository that fails every request, turned a missing injection into an error state at runtime instead of a compile error. The brief asks for an entry only where more than one view genuinely needs it, and two shallow screens have no such value: locale, Dynamic Type and color scheme are SwiftUI's own, and everything else reaches its view through a parameter. Rejected: each screen reading the entry itself, which `init` can't do, so each view would build its view model late and draw an empty first frame.
- **AC-2.1, AC-2.8, AC-2.9 and AC-2.11 are checked by hand,** like AC-1.13 and AC-1.14. Navigation, size changes and relaunch need UI tests, listed under "With more time"; the snapshots cover what each state looks like.

Settled during the story:
- **Snapshots of a collapsed split view with a selection.** A `NavigationSplitView` that starts collapsed with a selection shows the detail pushed, with a back button, so compact presets render the same split view as the others.
- **`List(selection:)` with the selected row filtered out.** SwiftUI leaves the binding alone. Measured on iOS 17.0, 26.0 and 27.0, on regular and compact width, with a split view hosted in a window: filtering the selected row out, emptying the list and bringing the row back never wrote to the binding. So the list takes the selection binding as it is. Rejected: a binding that ignores a `nil` while the selected code isn't among the rows, which would also swallow going back on compact width after a search had filtered the row out on regular width, leaving the user unable to leave the detail.
- **Country codes are case-sensitive.** `ch` returns `null` like an unknown code (checked against the live API on 2026-10-10). Codes always come from the list, so none is ever changed in between.
