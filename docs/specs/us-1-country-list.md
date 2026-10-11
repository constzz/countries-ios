# US-1: Country list

> Delivered in [PR #2](https://github.com/constzz/countries-ios/pull/2) on 2026-10-10. The spec isn't updated after merge: the code and the guides in `docs/` describe the app as it is now.
> **Changed since:** the repository reaches the screens through `RootView`'s `init`, and the `\.countriesRepository` environment entry is gone (US-2); placeholder states render on iPhone 17 Pro in light only (US-2); `AppEnvironment` reads the endpoint from the Info.plist, not `AppContainer` (PR #8).

*As a user, I can browse every country with its flag, name and continent, and search by name, so I can find a country quickly.*

## Scope
- **Domain:** the country summary, continent and error types, and the repository's search method.
- **Data:** the countries query, a case-insensitive search filter, the Apollo adapter with its error mapping and logging, and the repository behind one public factory.
- **UI:** the list screen on the shared MVI base, with search and pull-to-refresh, as the sidebar of a split view whose detail column shows a "Select a Country" placeholder; the shared state views; previews and snapshots of every list state. The US-0 placeholder root screen and its snapshots are replaced.
- **App:** the API endpoint as a build setting, a 15 s request timeout, and an entry point that runs an empty app while hosting tests.

**Non-goals:** selecting a row and the country detail (US-2), diacritic-insensitive search ("Reunion" doesn't find "Réunion"), localized country names, persistence beyond Apollo's in-memory cache, UI tests.

## Acceptance criteria
- [x] **AC-1.1** The list shows every country with its flag, name and continent, sorted by name.
- [x] **AC-1.2** Typing issues at most one query per 300 ms pause, and a term that is unchanged after trimming issues none.
- [x] **AC-1.3** Search is case-insensitive, and special characters such as `(` don't produce an error. A blank term lists every country.
- [x] **AC-1.4** The first load shows a full-screen loading state. Later searches and refreshes keep the current rows visible: a search still running after 0.5 s shows "Searching…" with a progress indicator pinned above the rows, and keeps it up while newer searches replace it; a refresh shows the system refresh control.
- [x] **AC-1.5** A search with no match shows an empty state that names the query.
- [x] **AC-1.6** A failure shows an error state with a Try Again button, which repeats the last request. Offline has its own message.
- [x] **AC-1.7** Rows keep their identity, the country code, across refresh and filtering.
- [x] **AC-1.8** Pull-to-refresh fetches fresh data from the network, bypassing the cache.
- [x] **AC-1.9** Snapshots cover the loading, loaded, searching, empty, error and offline states. Loaded and searching render on every device preset in light and dark; loading, empty, error and offline render on iPhone 17 Pro in light (see US-2's decisions). Every state also renders at accessibility XXXL on iPhone 17 Pro. On regular width (iPad, unfolded iPhone Duo where the system gives two columns) the list sits beside the "Select a Country" placeholder.
- [x] **AC-1.10** All list copy comes from the String Catalog: title, search prompt, loading, error and placeholder messages, the Try Again button and the VoiceOver announcements. The localization tests pass, and the loaded state's right-to-left snapshots (iPhone 17 Pro and iPad landscape) are mirrored.
- [x] **AC-1.11** Starting a load, search, refresh or retry cancels the request in flight, and a stale response never replaces newer results. A cancelled request never shows an error.
- [x] **AC-1.12** After each search, VoiceOver announces the number of results, with plural variants, or that there are none.
- [ ] **AC-1.13** A request with no response for 15 s ends in the error state.
- [ ] **AC-1.14** VoiceOver reads each row as one element, name then continent, without reading the flag.

## Screen contract
| State | UI |
|---|---|
| `content` is `.idle` or `.loading` | Full-screen progress with "Loading Countries…" |
| `.loaded(rows)` | One row per country: flag, name, and the continent below it in secondary text. Long names wrap. |
| `.loaded` or `.empty`, `isSearching` | The content stays; "Searching…" with a progress indicator, pinned above it |
| `.loaded` while refreshing | The rows stay; the system refresh control |
| `.empty(query:)` | `ContentUnavailableView.search(text: query)` |
| `.failed(.offline)` | "You're Offline", "Connect to the internet and try again.", Try Again |
| `.failed(other)` | "Couldn't Load Countries", "Something went wrong. Try again in a moment.", Try Again |
| Detail column, regular width | "Select a Country" placeholder |

One fetch runs at a time: a new one cancels the one in flight. Full-screen loading shows only when there's nothing to keep on screen (the first load, or after a failure).

## Errors and edge cases
| Scenario | Expected | UI state | Recovery |
|---|---|---|---|
| No connection | `.offline` | Offline error | Try Again |
| No response for 15 s | `.network` | Error | Try Again |
| Other transport or HTTP failure | `.network` | Error | Try Again |
| GraphQL errors, or `data: null` | `.server` | Error | Try Again |
| A newer request starts | `CancellationError` | Unchanged; the newest request decides | none needed |
| A response to an older request arrives | Ignored by the reducer | Unchanged | none needed |
| Term `(` or `C++` | Escaped, sent as a regex | Results or empty | none needed |
| Blank or whitespace-only term | No filter | Every country | none needed |
| Term unchanged after trimming, or back to the settled one within 300 ms | No request | Unchanged | none needed |
| No match | `[]` | `empty(query:)` | Edit the search |
| A blank term returns no countries | Refetched from the network if it came from the cache; still none → `.server` | Error | Try Again |
| A search fails while rows are shown | Error | Error replaces the rows | Try Again re-runs the term |
| A refresh fails | Error | Error replaces the rows | Try Again refreshes again |
| Unaccented input ("Reunion") | No match | `empty(query:)` | Left out (README) |
| Longest name ("South Georgia and the South Sandwich Islands") | Wraps | Loaded | none needed |

## Verification
Every automated test names the AC it covers, as in `@Test("AC-1.5 no match shows the empty state with the query")`, so `grep -rn "AC-1\." Packages AtlasUISnapshotTests` lists them. Checked by hand:

| AC | How |
|---|---|
| 1.13 | Network Link Conditioner at 100% loss: the error state appears after about 15 s |
| 1.14 | Accessibility Inspector on the iPhone 17 Pro simulator |

## Decisions
- **MVI on the list screen, on a shared base.** One state value, one action enum and one `reduce` per screen, and the shared `MVIViewModel` runs them: `send` reduces, assigns the state only when it changed, and returns a task for the work the action started. `reduce` lives on the view model and starts async work itself through `launchEffect`; the work's result comes back as an action, and stale responses are dropped in `reduce` by request id. Effects are one-time UI events only, so anything that must survive a redraw is state. Every screen conforms the same way, and each of its types sits in its own file. Rejected: a separate pure reducer that returns effects as values for the view model to run, which tests without doubles but splits each screen across two types and makes "effect" mean both work and UI events; MVVM with an event method per interaction and several observable properties, which spreads state changes across methods and widens the view model's surface.
- **The empty search state is the system's `ContentUnavailableView.search(text:)`.** It names the query, and iOS localizes its copy in every language it supports, so it needs no catalog entry. Rejected: our own "No countries match “…”" sentence in a hand-built `ContentUnavailableView`, which rebuilds a system component.
- **Snapshots render the split view with the list's inner view fed a fixed state.** No snapshot loads data or depends on timing. Rejected: the full screen with a stub repository, which would rely on the helper's few layout passes to settle.
- **Sorting is part of the repository contract.** The API sorts by code; every caller wants names. Rejected: sorting in the view model, which lets an API quirk leak into the UI.
- **Search is case-insensitive through the regex we send.** The API's `regex` filter is case-sensitive, so each cased letter goes out as `[xX]`, and regex metacharacters are escaped, since an unescaped `(` returns a server error. Letters whose case mapping isn't one-to-one, such as `ß`, pass through unchanged.
- **Retry repeats the last request with its cache policy,** so a failed refresh retries from the network. Rejected: retry always reading through the cache, which could bring back the data the refresh meant to replace.
- **A failure replaces the rows with the error state.** One state at a time keeps the screen contract small. Rejected: stale rows under an error banner, a sixth state for a rare case.
- **A running search shows "Searching…" pinned above the rows, not in the toolbar.** On iPhone the navigation bar hides while the search field is active, so a toolbar indicator vanished exactly when a search ran, and a slow or stalled search looked like nothing was happening. Above the rows it stays visible on every device and in one place (HIG Progress indicators: "Display progress indicators in a consistent location"). Rejected: replacing the rows with full-screen progress, which drops the content the user is refining.
- **"Searching…" appears only once a search has run for 0.5 s.** Most searches on a good connection answer within a few hundred milliseconds, and an indicator shown at once only blinks. The rows stay in place meanwhile, so a short wait needs no feedback. The delay lives in the view model, so `isSearching` says exactly what's on screen and the snapshots stay timing-free. Rejected: showing it at once, which flickered on every keystroke pause; and delaying it in the view, which keeps timing state outside the reducer and makes the searching snapshot wait.
- **Effects emitted while no view subscribes are dropped.** They are one-time UI events for the screen on display; with no view listening there's no screen to show them, and replaying them later would, for example, read out every search that finished while the list was off screen. The view subscribes before it sends `.appeared`, so nothing is lost at startup. Rejected: buffering effects for the next subscriber, which delivers them late and grows without limit while no view listens.
- **A view model's `init` only stores its dependencies.** SwiftUI builds a view's initial `@State` value every time it creates the view, and keeps only the first, so the others are discarded at once. The list's search pipe is built on first use, which makes a discarded view model a bare allocation, as Apple's `State` documentation asks of initial values. Rejected: creating the view model in `.task` behind an optional, which hides the cost instead of removing it and leaves the screen without a view model for its first frame; and the composition root owning view models, which needs a public view-model factory in AtlasUI.
- **The entry point decides whether the app hosts tests, once.** `AppLauncher` picks between `AtlasApp` and an empty `TestHostApp`, which still gives snapshot tests a window scene. `AppContainer` always builds real, non-optional dependencies, so each new dependency needs no test-only path. Rejected: an optional repository in `AppContainer` that is `nil` while hosting tests, which makes every dependency and every screen that reads it handle a case only tests produce.
- **The endpoint is a build setting.** `COUNTRIES_API_URL` in `Config/Shared.xcconfig` reaches the app through its Info.plist, so a build configuration or scheme can point at another server without a code change. The request timeout is a property of the network client, so it stays in AtlasData. Rejected: constants in `AppContainer`, which mix configuration into the composition root.
- **VoiceOver announces after searches only,** not after the first load or a refresh, where the content the user asked for is already on screen.
- **Snapshot images are drawn at @1x and match within 2 of 255 per color channel,** revising US-0's byte-for-byte comparison at native scale. With text in the search field, Liquid Glass renders with noise of 1–2 per channel from one run to the next, which byte comparison can't pass; layout, text and color changes differ by far more. At native scale the list's images alone were 27 MB, mostly the iPad sidebar material, and @1x brings them to under 7 MB. Rejected: byte comparison with the searching and empty states shown without search text, which isn't what users see; and @2x, which leaves the iPad images, already @2x, unchanged.
- **The snapshot helper renders one image at a time, with UIKit animations off and finite-duration animations removed before each capture.** Swift Testing runs tests in parallel, and Liquid Glass in one snapshot window picked up another window's rows; the search field's clear button was caught mid-fade; and the spinner was caught at a different angle each run.
- **AC-1.13 and AC-1.14 are checked by hand.** Testing them automatically needs a stalled network transport and UI tests; both are listed under "With more time".

Settled during the story:
- **Isolation of the Combine `sink`.** A plain `sink` closure formed in a `@MainActor` method inherits main-actor isolation, and it runs on the main queue after `debounce(for:scheduler: DispatchQueue.main)`. It compiles with zero warnings on Swift 6.2 (Xcode 26.0.1) and Swift 6.4 (Xcode 27.1), with no `MainActor.assumeIsolated` and no `Task` hop.
- **Apollo 2.4.0 rethrows a `URLError` unwrapped.** Other failures: `ResponseCodeInterceptor.ResponseCodeError` (non-2xx) maps to `.network`, `JSONResponseParsingError`, `JSONDecodingError` (thrown unwrapped by cache reads and some conversions) and `GraphQLExecutionError` to `.decoding`, and `URLError.cancelled` counts as cancellation, like `CancellationError`.
