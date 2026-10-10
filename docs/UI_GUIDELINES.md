# UI guidelines

Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) are the design reference. There is no custom design: system components, system colors and system text styles come first. When a HIG section drives a decision, the commit or pull request names it.

## Design tokens
Screens never name a system color or text style directly. They use semantic tokens defined once in `CountriesUI/DesignSystem/`, named after their role:

```swift
// DesignSystem/Colors.swift
extension ShapeStyle where Self == HierarchicalShapeStyle {
  static var secondaryText: HierarchicalShapeStyle { .secondary }
}

// DesignSystem/Typography.swift
extension Font {
  static var rowTitle: Font { .body }
}

// In a screen
Text(country.name).font(.rowTitle)
```

- Tokens are static members, the same shape as SwiftUI's own `.tint` or `.headline`. There's no theme object in the environment: light and dark mode come from the system, and there is no runtime theme switching.
- A token's value is always a system semantic color or a system text style, so dark mode, increased contrast and Dynamic Type keep working with no extra code.
- Restyling a role is a one-line change in one file.
- System components keep their own styling: `List`, `LabeledContent`, `ContentUnavailableView`, navigation and search bars get no tokens. Tokens cover only what the app styles itself.
- Lint enforces this: the `design_tokens_only` rule rejects system colors and text styles in CountriesUI outside `DesignSystem/`.

## Colors
- Color tokens map to system semantic colors: `.primary`, `.secondary`, `.tint`, `Color(.systemGroupedBackground)` and so on. They adapt to light mode, dark mode and increased contrast on their own.
- Text colors are `HierarchicalShapeStyle` tokens (`.secondary`), not `Color` tokens. Hierarchical styles resolve against their context, so secondary text stays readable inside a selected sidebar row.
- No `preferredColorScheme`.
- A custom color is added only for a brand accent, as a colorset with Any and Dark appearances in `CountriesUI/Resources/Colors.xcassets`, exposed as a token.
- Lint rejects hard-coded colors anywhere in CountriesUI: `Color(red:…)`, `UIColor(red:…)`, `#colorLiteral`, `Color(hex:…)`, `.black` and `.white`.

## Typography and Dynamic Type
- Font tokens map to system text styles (`.body`, `.headline`, `.caption`…), never fixed point sizes. Sizes that must scale use `@ScaledMetric`.
- The flag emoji scales with a text style.
- Layouts that run out of room at accessibility sizes switch axis or use `ViewThatFits` instead of truncating.
- Detail rows are `LabeledContent` inside a `List`, which handles Dynamic Type and dark mode natively.

## Spacing
Small token enums in `DesignSystem/` next to the color and font tokens, e.g. `Spacing.small`, `Radius.card`. Standard list and form layouts use the system's own insets and need no tokens.

## Screen states
- Every screen has explicit states: loading, loaded, empty and failed.
- Full-screen loading only on the first load. Searches and refreshes keep the current rows visible with inline progress.
- Empty and error states are built on `ContentUnavailableView`. A search with no results uses `ContentUnavailableView.search(text:)`.
- Errors offer a retry that repeats the last request. The offline error has its own message.
- The `.loadState(_:retry:)` modifier renders the shared states, so both screens behave the same way.
- Missing values render as "None".

## Views
- The `body` is split into small private computed subviews.
- The outer view owns the view model with `@State` and sends `.appeared` from `.task`. The inner view takes a state and an action handler, so previews and snapshots can feed it any state.
- Previews cover loading, loaded, empty, error, long names, dark mode and the largest accessibility text size.

## Navigation
- `NavigationSplitView`: the country list in the sidebar, the selected country in the detail column. On compact width (iPhone, folded iPhone Duo) it collapses into a push stack by itself.
- The sidebar is a `List(selection:)` keyed by the country `code`, with `.searchable` and `.refreshable`.
- Selection lives in the root view, not in either view model:
  - on regular width the selected row stays highlighted, and before any selection the detail column shows a "Select a country" placeholder;
  - if a search filters out the selected country, its detail stays visible, and refresh keeps the selection;
  - going back on compact width clears the selection;
  - folding, unfolding, rotating and resizing keep the selected country, and each window restores it after relaunch with `@SceneStorage`.

## Accessibility
- In list rows the flag emoji is `.accessibilityHidden(true)`, and the row is one combined element, so VoiceOver reads the name once.
- After each search, VoiceOver announces the number of results, or that there are none, using the catalog's plural variants.
- Accessibility identifiers are added together with the UI tests that use them.

## Localization and right-to-left
The app ships in English but is localization-ready: adding a language is a catalog and project-setting change with no code changes ([development guide](DEVELOPMENT.md#adding-a-language)).
- All user-facing copy lives in `CountriesUI/Resources/Localizable.xcstrings`, with a translator comment on every key. The English text is the key.
- In views: `Text("Countries", bundle: .module)`. Outside views: `String(localized: "…", bundle: .module, comment: "…")`. Without `bundle: .module`, SwiftUI looks the key up in the app's bundle and the package's translations are never used. Lint flags `Text("…")` without a bundle in CountriesUI.
- SwiftUI conveniences that take no bundle, such as `Button("…")`, `Label("…", systemImage:)`, `navigationTitle("…")` and `ContentUnavailableView("…", systemImage:)`, are replaced by their forms that take a `Text`.
- Data from the API is shown with `Text(verbatim:)`. Country, capital and continent names stay in English, because search matches the English names.
- Whole sentences with placeholders, never joined fragments: `Text("No countries match “\(query)”", bundle: .module)`. Quotation marks belong to the catalog string, so each language can use its own.
- Lists of values use the locale's list format, `.formatted(.list(type: .and))`, never `joined(separator:)`.
- Layout uses leading and trailing only, never left, right or fixed x-offsets, so SwiftUI mirrors it. Directional SF Symbols use the forward/backward names (`chevron.forward`), so they flip.
- Before each UI pull request, run the app with the scheme's "Show non-localized strings", "Right-to-Left Pseudolanguage" and "Double-Length Pseudolanguage" options.

## Snapshot tests
Every UI change ships snapshot tests for each state it affects, recorded and inspected before committing.
- One call such as `assertSnapshots(of: view, named: "COUNTRY_LIST_EMPTY")` renders every device preset in light and dark. A test can't forget a device.

  | Preset | Size (pt) | Notes |
  |---|---|---|
  | `iPhone17Pro` | 402 × 874 | compact width |
  | `iPhoneDuoFolded` | 466 × 678 | cover screen |
  | `iPhoneDuoUnfolded` | 951 × 669 | inner screen, in the posture it opens in |
  | `iPad11Portrait` | 820 × 1180 | |
  | `iPad11Landscape` | 1180 × 820 | both split-view columns |

  Safe areas and size classes were read from the running simulators. Liquid Glass and other materials appear in the images as on a device. Images are drawn at @1x; layout uses each device's real display scale.
- iPhone 17 Pro also gets the largest accessibility text size, in light. Loaded states also get a right-to-left image on iPhone 17 Pro in light.
- Snapshots render inner views fed a fixed state, never views that load data. The locale is `en_US`.
- File names follow `<SCREEN>_<STATE>_<preset>_<light|dark>[_<variant>]`, e.g. `COUNTRY_LIST_EMPTY_iPhoneDuoUnfolded_dark.png`. Reference images live in a `snapshots/` folder next to the test file.
- Images are recorded and compared only on Xcode 27.1 with the iOS 27.0 simulator, because rendering differs between OS versions. Elsewhere the tests are skipped with a reason.
- Recording and reviewing: [development guide](DEVELOPMENT.md#snapshot-tests).
