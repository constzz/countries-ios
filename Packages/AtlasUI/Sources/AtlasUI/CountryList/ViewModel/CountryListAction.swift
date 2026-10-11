import AtlasMVI

enum CountryListAction: MVIAction {
  case appeared
  case searchTextChanged(String)
  case refreshRequested
  case retryTapped
}
