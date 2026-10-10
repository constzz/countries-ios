import CountriesDomain
import Testing
@testable import CountriesUI

@Suite("CountryListReducer")
struct CountryListReducerTests {
  private let rows = Array(CountrySummary.samples.prefix(4))

  // MARK: Loading

  @Test("AC-1.4 the first load shows loading")
  func firstLoadShowsLoading() {
    let (state, effects) = CountryListReducer.reduce(CountryListState(), .appeared)

    #expect(state.content == .loading)
    #expect(effects == [.fetch(CountriesRequest(id: 1, term: "", forceRefresh: false, kind: .load))])
  }

  @Test("AC-1.1 a response shows the loaded rows")
  func responseShowsTheLoadedRows() {
    let state = loaded(rows)

    #expect(state.content == .loaded(rows))
  }

  @Test("AC-1.4 appearing again fetches nothing")
  func appearingAgainFetchesNothing() {
    let (state, effects) = CountryListReducer.reduce(loaded(rows), .appeared)

    #expect(state == loaded(rows))
    #expect(effects.isEmpty)
  }

  // MARK: Searching

  @Test("AC-1.4 a search keeps rows visible while searching")
  func searchKeepsRowsVisible() {
    let (state, effects) = CountryListReducer.reduce(loaded(rows), .searchSettled("ger"))

    #expect(state.content == .loaded(rows))
    #expect(state.isSearching)
    #expect(state.query == "ger")
    #expect(effects == [.fetch(CountriesRequest(id: 2, term: "ger", forceRefresh: false, kind: .search))])
  }

  @Test("AC-1.4 a search with nothing on screen shows loading")
  func searchWithNothingOnScreenShowsLoading() {
    let failed = respond(to: CountryListReducer.reduce(CountryListState(), .appeared).0, with: .failure(.network))

    let (state, _) = CountryListReducer.reduce(failed, .searchSettled("ger"))

    #expect(state.content == .loading)
    #expect(!state.isSearching)
  }

  @Test("AC-1.5 no match shows the empty state with the query")
  func noMatchShowsTheEmptyState() {
    let searching = CountryListReducer.reduce(loaded(rows), .searchSettled("zzz")).0

    let state = respond(to: searching, with: .success([]))

    #expect(state.content == .empty(query: "zzz"))
    #expect(!state.isSearching)
  }

  @Test("AC-1.2 typing updates the search text and feeds the search pipe")
  func typingFeedsTheSearchPipe() {
    let (state, effects) = CountryListReducer.reduce(loaded(rows), .searchTextChanged("Ger"))

    #expect(state.searchText == "Ger")
    #expect(state.request == loaded(rows).request)
    #expect(effects == [.debounce("Ger")])
  }

  // MARK: Refreshing

  @Test("AC-1.4 a refresh keeps rows visible")
  func refreshKeepsRowsVisible() {
    let (state, _) = CountryListReducer.reduce(loaded(rows), .refreshRequested)

    #expect(state.content == .loaded(rows))
    #expect(!state.isSearching)
  }

  @Test("AC-1.8 refresh fetches the current query from the network")
  func refreshFetchesFromTheNetwork() {
    let searched = respond(to: CountryListReducer.reduce(loaded(rows), .searchSettled("a")).0, with: .success(rows))

    let (_, effects) = CountryListReducer.reduce(searched, .refreshRequested)

    #expect(effects == [.fetch(CountriesRequest(id: 3, term: "a", forceRefresh: true, kind: .refresh))])
  }

  @Test("AC-1.7 rows keep their codes across refresh and filtering")
  func rowsKeepTheirCodes() {
    let refreshing = CountryListReducer.reduce(loaded(rows), .refreshRequested).0
    let refreshed = respond(to: refreshing, with: .success(rows))
    let filtering = CountryListReducer.reduce(refreshed, .searchSettled("an")).0
    let filtered = respond(to: filtering, with: .success([rows[1], rows[2]]))

    #expect(ids(refreshed) == rows.map(\.code))
    #expect(ids(filtered) == [rows[1].code, rows[2].code])
  }

  // MARK: Failing

  @Test("AC-1.6 a failure shows the error")
  func failureShowsTheError() {
    let searching = CountryListReducer.reduce(loaded(rows), .searchSettled("ger")).0

    let state = respond(to: searching, with: .failure(.offline))

    #expect(state.content == .failed(.offline))
    #expect(!state.isSearching)
  }

  @Test("AC-1.6 retry repeats the last request")
  func retryRepeatsTheLastRequest() {
    let refreshing = CountryListReducer.reduce(loaded(rows), .refreshRequested).0
    let failed = respond(to: refreshing, with: .failure(.network))

    let (state, effects) = CountryListReducer.reduce(failed, .retryTapped)

    #expect(state.content == .loading)
    #expect(effects == [.fetch(CountriesRequest(id: 3, term: "", forceRefresh: true, kind: .refresh))])
  }

  // MARK: Ordering

  @Test("AC-1.11 a stale response never replaces newer results")
  func staleResponseIsIgnored() throws {
    let first = CountryListReducer.reduce(loaded(rows), .searchSettled("a")).0
    let second = CountryListReducer.reduce(first, .searchSettled("ab")).0
    let answered = respond(to: second, with: .success([rows[0]]))

    let (state, effects) = try CountryListReducer.reduce(
      answered,
      .responseReceived(requestID: #require(first.request).id, .success(rows))
    )

    #expect(state == answered)
    #expect(effects.isEmpty)
  }

  // MARK: Announcing

  @Test("AC-1.12 a search announces its result count")
  func searchAnnouncesItsResultCount() {
    let searching = CountryListReducer.reduce(loaded(rows), .searchSettled("a")).0
    let requestID = searching.request?.id ?? 0

    let (_, found) = CountryListReducer.reduce(searching, .responseReceived(requestID: requestID, .success(rows)))
    let (_, none) = CountryListReducer.reduce(searching, .responseReceived(requestID: requestID, .success([])))

    #expect(found == [.announce(resultCount: rows.count)])
    #expect(none == [.announce(resultCount: 0)])
  }

  @Test("AC-1.12 load and refresh announce nothing")
  func loadAndRefreshAnnounceNothing() {
    let loading = CountryListReducer.reduce(CountryListState(), .appeared).0
    let refreshing = CountryListReducer.reduce(loaded(rows), .refreshRequested).0

    for state in [loading, refreshing] {
      let requestID = state.request?.id ?? 0
      let (_, effects) = CountryListReducer.reduce(state, .responseReceived(requestID: requestID, .success(rows)))
      #expect(effects.isEmpty)
    }
  }

  // MARK: Helpers

  /// The state after the first load returned `rows`.
  private func loaded(_ rows: [CountrySummary]) -> CountryListState {
    respond(to: CountryListReducer.reduce(CountryListState(), .appeared).0, with: .success(rows))
  }

  /// Answers the latest request in `state`.
  private func respond(
    to state: CountryListState,
    with result: Result<[CountrySummary], CountriesError>
  ) -> CountryListState {
    CountryListReducer.reduce(state, .responseReceived(requestID: state.request?.id ?? 0, result)).0
  }

  private func ids(_ state: CountryListState) -> [String] {
    guard case let .loaded(rows) = state.content else {
      return []
    }
    return rows.map(\.id)
  }
}
