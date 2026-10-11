// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "AtlasUI",
  defaultLocalization: "en",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "AtlasUI", targets: ["AtlasUI"]),
  ],
  dependencies: [
    .package(path: "../AtlasDomain"),
  ],
  targets: [
    .target(
      name: "AtlasUI",
      dependencies: ["AtlasDomain"],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "AtlasUITests",
      dependencies: ["AtlasUI", "AtlasDomain"],
      swiftSettings: swiftSettings
    ),
  ]
)
