import SwiftUI
import Testing
import UIKit

/// Renders `view` on every device preset in light and dark, plus the largest accessibility text
/// size on iPhone 17 Pro, and compares each image with its reference in `snapshots/` next to the
/// calling test file. Images are named `<name>_<preset>_<variant>.png`.
///
/// - Parameter rightToLeft: Also renders a right-to-left image on iPhone 17 Pro and iPad landscape,
///   in light.
@MainActor
func assertSnapshots(
  of view: some View,
  named name: String,
  rightToLeft: Bool = false,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) async {
  var shots: [(SnapshotPreset, SnapshotVariant)] = SnapshotPreset.all.flatMap { [($0, .light), ($0, .dark)] }
  shots.append((.iPhone17Pro, .lightAccessibilityXXXL))
  if rightToLeft {
    shots += [(.iPhone17Pro, .lightRightToLeft), (.iPad11Landscape, .lightRightToLeft)]
  }

  let folder = URL(filePath: "\(filePath)").deletingLastPathComponent().appending(path: "snapshots")
  for (preset, variant) in shots {
    let imageName = "\(name)_\(preset.name)_\(variant.suffix)"
    do {
      let png = try await render(view, on: preset, variant)
      compare(png, with: folder.appending(path: "\(imageName).png"), sourceLocation: sourceLocation)
    } catch {
      Issue.record("Could not render \(imageName): \(error)", sourceLocation: sourceLocation)
    }
  }
}

// MARK: - SnapshotError

enum SnapshotError: Error {
  case noWindowScene
  case pngEncodingFailed
}

/// Hosts the view in a window with the preset's size, safe area and traits, and renders it to PNG.
///
/// The window joins the test host's window scene, behind the app's own window: Liquid Glass and
/// other materials are drawn by the render server, so `drawHierarchy` captures them only for a
/// window in a scene. The image is forced to sRGB so it doesn't depend on the Mac's display.
@MainActor
private func render(_ view: some View, on preset: SnapshotPreset, _ variant: SnapshotVariant) async throws -> Data {
  guard let scene = UIApplication.shared.connectedScenes.lazy.compactMap({ $0 as? UIWindowScene }).first else {
    throw SnapshotError.noWindowScene
  }
  let controller = UIHostingController(
    rootView: view
      .environment(\.locale, Locale(identifier: "en_US"))
      .transaction { $0.disablesAnimations = true }
  )

  let window = SnapshotWindow(windowScene: scene, safeArea: preset.safeArea)
  window.frame = CGRect(origin: .zero, size: preset.size)
  window.windowLevel = .normal - 1
  window.traitOverrides.userInterfaceIdiom = preset.idiom
  window.traitOverrides.horizontalSizeClass = preset.horizontalSizeClass
  window.traitOverrides.verticalSizeClass = preset.verticalSizeClass
  window.traitOverrides.displayScale = preset.scale
  window.traitOverrides.displayGamut = .SRGB
  window.traitOverrides.userInterfaceStyle = variant.style
  window.traitOverrides.preferredContentSizeCategory = variant.contentSize
  window.traitOverrides.layoutDirection = variant.layoutDirection
  window.rootViewController = controller
  window.isHidden = false
  defer { window.isHidden = true }

  // Give SwiftUI a few run-loop turns to settle its layout.
  for _ in 0 ..< 3 {
    controller.view.layoutIfNeeded()
    await Task.yield()
  }

  let format = UIGraphicsImageRendererFormat()
  format.scale = preset.scale
  format.opaque = true
  format.preferredRange = .standard
  let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
  }
  guard let png = image.pngData() else { throw SnapshotError.pngEncodingFailed }
  return png
}

/// Compares PNG bytes with the reference image, or records the image when recording.
@MainActor
private func compare(_ png: Data, with reference: URL, sourceLocation: SourceLocation) {
  let name = reference.lastPathComponent
  if SnapshotEnvironment.isRecording {
    do {
      try FileManager.default.createDirectory(
        at: reference.deletingLastPathComponent(), withIntermediateDirectories: true
      )
      try png.write(to: reference)
      Issue.record(
        "Recorded \(name). Recording always fails; run the tests again without SNAPSHOT_RECORD.",
        sourceLocation: sourceLocation
      )
    } catch {
      Issue.record("Could not record \(name): \(error)", sourceLocation: sourceLocation)
    }
    return
  }

  guard let stored = try? Data(contentsOf: reference) else {
    Issue.record(
      "No reference image \(name). Record it with the RecordSnapshots test plan.",
      sourceLocation: sourceLocation
    )
    return
  }
  guard stored != png else { return }

  let actual = FileManager.default.temporaryDirectory.appending(path: name)
  do {
    try png.write(to: actual)
    Issue.record(
      "\(name) doesn't match its reference image.\nReference: \(reference.path)\nActual: \(actual.path)",
      sourceLocation: sourceLocation
    )
  } catch {
    Issue.record("\(name) doesn't match its reference image (\(error)).", sourceLocation: sourceLocation)
  }
}

// MARK: - SnapshotWindow

/// A window with a fixed safe area. Without it the window would take its safe area from the
/// simulator's screen, whatever device the tests run on.
private final class SnapshotWindow: UIWindow {
  private let fixedSafeArea: UIEdgeInsets

  init(windowScene: UIWindowScene, safeArea: UIEdgeInsets) {
    fixedSafeArea = safeArea
    super.init(windowScene: windowScene)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var safeAreaInsets: UIEdgeInsets {
    fixedSafeArea
  }
}
