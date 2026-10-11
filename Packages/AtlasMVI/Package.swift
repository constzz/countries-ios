// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "AtlasMVI",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "AtlasMVI", targets: ["AtlasMVI"]),
    .library(name: "AtlasMVITesting", targets: ["AtlasMVITesting"]),
  ],
  targets: [
    .target(name: "AtlasMVI", swiftSettings: swiftSettings),
    .target(name: "AtlasMVITesting", dependencies: ["AtlasMVI"], swiftSettings: swiftSettings),
    .testTarget(
      name: "AtlasMVITests",
      dependencies: ["AtlasMVI", "AtlasMVITesting"],
      swiftSettings: swiftSettings
    ),
  ]
)
