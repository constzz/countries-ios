import CountriesDomain
import SwiftUI

/// A screen state that replaces the content: loading, an empty search or a failure.
enum LoadPhase: Equatable {
  case loading
  case empty(query: String)
  case failed(CountriesError)
}

extension View {
  /// Covers the content with the view for `phase`, or shows the content when it's `nil`. The
  /// content stays in place underneath, so its search field and refresh control keep working.
  func loadState(
    _ phase: LoadPhase?,
    subject: ErrorCopy.Subject,
    loadingLabel: Text,
    retry: @escaping () -> Void
  ) -> some View {
    overlay {
      if let phase {
        LoadStateView(phase: phase, subject: subject, loadingLabel: loadingLabel, retry: retry)
      }
    }
  }
}

private struct LoadStateView: View {
  let phase: LoadPhase
  let subject: ErrorCopy.Subject
  let loadingLabel: Text
  let retry: () -> Void

  var body: some View {
    switch phase {
    case .loading:
      ProgressView { loadingLabel }
    case let .empty(query):
      ContentUnavailableView.search(text: query)
    case let .failed(error):
      failure(ErrorCopy(error, subject: subject))
    }
  }

  private func failure(_ copy: ErrorCopy) -> some View {
    ContentUnavailableView {
      Label {
        Text(copy.title)
      } icon: {
        Image(systemName: copy.systemImage)
      }
    } description: {
      Text(copy.message)
    } actions: {
      Button(action: retry) {
        Text("Try Again", bundle: .module, comment: "Button on an error state that repeats the failed request.")
      }
      .buttonStyle(.bordered)
    }
  }
}
