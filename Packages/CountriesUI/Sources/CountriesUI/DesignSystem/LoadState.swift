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
  /// content stays in place underneath, so it keeps its state.
  func loadState(
    _ phase: LoadPhase?,
    subject: ErrorCopy.Subject,
    loadingLabel: Text,
    retry: @escaping () -> Void
  ) -> some View {
    modifier(LoadStateModifier(phase: phase, subject: subject, loadingLabel: loadingLabel, retry: retry))
  }
}

private struct LoadStateModifier: ViewModifier {
  let phase: LoadPhase?
  let subject: ErrorCopy.Subject
  let loadingLabel: Text
  let retry: () -> Void

  func body(content: Content) -> some View {
    content.overlay {
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
      if copy.canRetry {
        Button(action: retry) {
          Text(.errorRetry)
        }
        .buttonStyle(.bordered)
      }
    }
  }
}
