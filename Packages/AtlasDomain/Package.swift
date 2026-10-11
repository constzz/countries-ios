// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "AtlasDomain",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "AtlasDomain", targets: ["AtlasDomain"]),
  ],
  targets: [
    .target(name: "AtlasDomain", swiftSettings: swiftSettings),
    .testTarget(name: "AtlasDomainTests", dependencies: ["AtlasDomain"], swiftSettings: swiftSettings),
  ]
)
