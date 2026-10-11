import AtlasMVI

enum CountryListEffect: MVIEffect {
  /// Text for VoiceOver to read when a search finishes.
  case announce(String)
}
