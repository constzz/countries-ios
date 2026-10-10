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
  guard SnapshotEnvironment.isReference else {
    Issue.record("Record snapshots on Xcode 27.1 with the iOS 27.0 simulator.", sourceLocation: sourceLocation)
    return
  }

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

enum SnapshotError: Error {
  case noWindowScene
  case pngEncodingFailed
  /// Ten captures in a row differed.
  case unstable
}

/// Hosts the view in a window with the preset's size, safe area and traits, and renders it to PNG.
///
/// The window joins the test host's window scene, behind the app's own window: Liquid Glass and
/// other materials are drawn by the render server, so `drawHierarchy` captures them only for a
/// window in a scene. The image is forced to sRGB so it doesn't depend on the Mac's display.
@MainActor
private func render(_ view: some View, on preset: SnapshotPreset, _ variant: SnapshotVariant) async throws -> Data {
  await RenderGate.shared.enter()
  defer { RenderGate.shared.leave() }
  let scene = try await hostScene()
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

  // SwiftUI's transaction doesn't reach UIKit: with animations on, the search field's clear
  // button is captured mid-fade. Off, views take their final state at once.
  UIView.setAnimationsEnabled(false)
  defer { UIView.setAnimationsEnabled(true) }

  window.rootViewController = controller
  window.isHidden = false
  defer { window.isHidden = true }

  // Some views settle a moment after layout (the search field shows its clear button late), so
  // capture until two images taken a short while apart match.
  var previous = Data()
  for _ in 0 ..< 10 {
    controller.view.layoutIfNeeded()
    try await Task.sleep(for: .milliseconds(50))
    let png = try capture(window)
    if png == previous {
      return png
    }
    previous = png
  }
  throw SnapshotError.unstable
}

/// Draws the window as the render server shows it, at @1x. The window keeps the device's display
/// scale, so layout matches the device; only the image is smaller, which keeps the reference images
/// a reviewable size.
@MainActor
private func capture(_ window: UIWindow) throws -> Data {
  removeMotion(from: window.layer)
  let format = UIGraphicsImageRendererFormat()
  format.scale = 1
  format.opaque = true
  format.preferredRange = .standard
  let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
  }
  guard let png = image.pngData() else { throw SnapshotError.pngEncodingFailed }
  return png
}

/// The test host's active window scene. The first test can start before the scene connects, so
/// this waits up to about five seconds for it.
@MainActor
private func hostScene() async throws -> UIWindowScene {
  for _ in 0 ..< 100 {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    if let scene = scenes.first(where: { $0.activationState == .foregroundActive }) {
      return scene
    }
    try await Task.sleep(for: .milliseconds(50))
  }
  throw SnapshotError.noWindowScene
}

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
  guard !matches(png, stored) else { return }

  Attachment.record(png, named: name, sourceLocation: sourceLocation)
  Issue.record(
    "\(name) doesn't match its reference image. The rendered image is attached to the test result.",
    sourceLocation: sourceLocation
  )
}

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

/// Removes animations with a finite duration, such as a spinner's frames or a fade UIKit starts
/// itself, so each layer draws its final state instead of whichever frame the capture lands on.
/// Liquid Glass ties its shapes to other layers with animations of infinite duration; those stay.
@MainActor
private func removeMotion(from layer: CALayer) {
  for key in layer.animationKeys() ?? [] where layer.animation(forKey: key)?.duration.isFinite == true {
    layer.removeAnimation(forKey: key)
  }
  for sublayer in layer.sublayers ?? [] {
    removeMotion(from: sublayer)
  }
}

/// Lets one render run at a time. Swift Testing runs tests in parallel, and every snapshot window
/// joins the same scene: with two on screen, Liquid Glass in one picks up the other's content.
@MainActor
private final class RenderGate {
  static let shared = RenderGate()

  private var isBusy = false
  private var waiting: [CheckedContinuation<Void, Never>] = []

  func enter() async {
    if isBusy {
      await withCheckedContinuation { waiting.append($0) }
    } else {
      isBusy = true
    }
  }

  /// Hands the gate to the next render in line, or opens it.
  func leave() {
    if waiting.isEmpty {
      isBusy = false
    } else {
      waiting.removeFirst().resume()
    }
  }
}

/// Whether two PNGs show the same image. Each channel may differ by up to 2 of 255: Liquid Glass
/// over a search field holding text renders with that much noise from one run to the next. Any
/// change to layout, text or color differs by far more.
private func matches(_ png: Data, _ reference: Data, tolerance: Int = 2) -> Bool {
  if png == reference {
    return true
  }
  guard let lhs = RGBAImage(png), let rhs = RGBAImage(reference), lhs.size == rhs.size else {
    return false
  }
  return zip(lhs.bytes, rhs.bytes).allSatisfy { abs(Int($0) - Int($1)) <= tolerance }
}

/// A PNG decoded to 8-bit sRGB RGBA bytes.
private struct RGBAImage {
  let size: CGSize
  let bytes: [UInt8]

  init?(_ png: Data) {
    guard let image = UIImage(data: png)?.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else {
      return nil
    }
    let (width, height) = (image.width, image.height)
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
      guard let context = CGContext(
        data: buffer.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
        return false
      }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else {
      return nil
    }
    size = CGSize(width: width, height: height)
    self.bytes = bytes
  }
}
