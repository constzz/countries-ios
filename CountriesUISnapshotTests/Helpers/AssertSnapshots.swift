import SwiftUI
import Testing
import UIKit

/// Renders `view` on every device preset in light and dark, plus the largest accessibility text
/// size on iPhone 17 Pro, and compares each image with its reference in `snapshots/` next to the
/// calling test file. Images are named `<name>_<preset>_<variant>.png`.
///
/// - Parameters:
///   - everyDevice: When `false`, renders only iPhone 17 Pro in light, plus the largest
///     accessibility text size.
///   - rightToLeft: Also renders a right-to-left image on iPhone 17 Pro and iPad landscape, in
///     light.
@MainActor
func assertSnapshots(
  of view: some View,
  named name: String,
  everyDevice: Bool = true,
  rightToLeft: Bool = false,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) async {
  guard SnapshotEnvironment.isReference else {
    Issue.record("Record snapshots on Xcode 27.1 with the iOS 27.0 simulator.", sourceLocation: sourceLocation)
    return
  }

  let presets = everyDevice ? SnapshotPreset.all : [.iPhone17Pro]
  let variants: [SnapshotVariant] = everyDevice ? [.light, .dark] : [.light]
  var shots = presets.flatMap { preset in variants.map { (preset, $0) } }
  shots.append((.iPhone17Pro, .lightAccessibilityXXXL))
  if rightToLeft {
    shots += [(.iPhone17Pro, .lightRightToLeft), (.iPad11Landscape, .lightRightToLeft)]
  }

  let folder = URL(filePath: "\(filePath)").deletingLastPathComponent().appending(path: "snapshots")
  for (preset, variant) in shots {
    let imageName = "\(name)_\(preset.name)_\(variant.suffix)"
    do {
      let snapshot = try await render(view, on: preset, variant)
      compare(snapshot, with: folder.appending(path: "\(imageName).png"), sourceLocation: sourceLocation)
    } catch {
      Issue.record("Could not render \(imageName): \(error)", sourceLocation: sourceLocation)
    }
  }
}

enum SnapshotError: Error {
  case noWindowScene
  case captureFailed
  case pngEncodingFailed
  /// The captures didn’t settle within about ten seconds. `waitingFor` names the image view still
  /// undrawn at the end, if one was.
  case unstable(waitingFor: String?)
}

/// A rendered image: its PNG, to record or attach, and its pixels, to compare.
private struct Snapshot {
  let png: Data
  let pixels: RGBAImage
}

/// Hosts the view in a window with the preset's size, safe area and traits, and renders it.
///
/// The window joins the test host's window scene, behind the app's own window: Liquid Glass and
/// other materials are drawn by the render server, so `drawHierarchy` captures them only for a
/// window in a scene. The image is forced to sRGB so it doesn't depend on the Mac's display.
@MainActor
private func render(_ view: some View, on preset: SnapshotPreset, _ variant: SnapshotVariant) async throws -> Snapshot {
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

  // Some views settle a moment after layout, so capture until two images taken a short while
  // apart match, within the same tolerance as the reference: Liquid Glass may differ that much
  // from one frame to the next. On a fresh simulator, system images such as the search field's
  // clear button reach their layers a second or two late, and captures taken until then match
  // each other without them, so no capture counts while an image is undrawn.
  var previous: RGBAImage?
  var undrawn: UIImageView?
  for _ in 0 ..< 200 {
    controller.view.layoutIfNeeded()
    try await Task.sleep(for: .milliseconds(50))
    undrawn = undrawnImageView(in: window)
    if undrawn != nil {
      previous = nil
      continue
    }
    let image = try capture(window)
    guard let pixels = RGBAImage(image) else { throw SnapshotError.captureFailed }
    if let previous, matches(pixels, previous) {
      guard let png = UIImage(cgImage: image).pngData() else { throw SnapshotError.pngEncodingFailed }
      return Snapshot(png: png, pixels: pixels)
    }
    previous = pixels
  }
  throw SnapshotError.unstable(waitingFor: undrawn.map(describe))
}

/// Draws the window as the render server shows it, at @1x. The window keeps the device's display
/// scale, so layout matches the device; only the image is smaller, which keeps the reference images
/// a reviewable size.
@MainActor
private func capture(_ window: UIWindow) throws -> CGImage {
  removeMotion(from: window.layer)
  let format = UIGraphicsImageRendererFormat()
  format.scale = 1
  format.opaque = true
  format.preferredRange = .standard
  let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
  }
  guard let cgImage = image.cgImage else { throw SnapshotError.captureFailed }
  return cgImage
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
private func compare(_ snapshot: Snapshot, with reference: URL, sourceLocation: SourceLocation) {
  let name = reference.lastPathComponent
  if SnapshotEnvironment.isRecording {
    do {
      try FileManager.default.createDirectory(
        at: reference.deletingLastPathComponent(), withIntermediateDirectories: true
      )
      try snapshot.png.write(to: reference)
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
  if let stored = RGBAImage(stored), matches(snapshot.pixels, stored) {
    return
  }

  Attachment.record(snapshot.png, named: name, sourceLocation: sourceLocation)
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

/// The first image view on screen that holds an image its layer doesn't show yet. Hidden and
/// transparent views and their subviews are skipped, as are empty image views: none is drawn, so
/// their layers may never get contents.
@MainActor
private func undrawnImageView(in view: UIView) -> UIImageView? {
  guard !view.isHidden, view.alpha > 0 else {
    return nil
  }
  let imageView = view as? UIImageView
  if let imageView, imageView.image != nil, !imageView.bounds.isEmpty, imageView.layer.contents == nil {
    return imageView
  }
  for subview in view.subviews {
    if let imageView = undrawnImageView(in: subview) {
      return imageView
    }
  }
  return nil
}

/// The image an image view holds and where it sits in its window, for a failure message.
@MainActor
private func describe(_ imageView: UIImageView) -> String {
  let image = imageView.image.map { String(describing: $0) } ?? "no image"
  return "\(image) at \(imageView.convert(imageView.bounds, to: nil))"
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

/// Whether two images are the same. Each channel may differ by up to 2 of 255: Liquid Glass over
/// a search field holding text renders with that much noise from one run to the next. Any change
/// to layout, text or color differs by far more.
private func matches(_ lhs: RGBAImage, _ rhs: RGBAImage, tolerance: Int = 2) -> Bool {
  guard lhs.size == rhs.size else {
    return false
  }
  if lhs.bytes == rhs.bytes {
    return true
  }
  return zip(lhs.bytes, rhs.bytes).allSatisfy { abs(Int($0) - Int($1)) <= tolerance }
}

/// An image as 8-bit sRGB RGBA bytes.
private struct RGBAImage {
  let size: CGSize
  let bytes: [UInt8]

  init?(_ png: Data) {
    guard let image = UIImage(data: png)?.cgImage else {
      return nil
    }
    self.init(image)
  }

  init?(_ image: CGImage) {
    guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
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
