enum CountryListEffect: MVIEffect {
  /// Tell VoiceOver how many countries a search found.
  case announce(resultCount: Int)
}
