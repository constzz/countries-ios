// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "CountriesDomain",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "CountriesDomain", targets: ["CountriesDomain"]),
  ],
  targets: [
    .target(name: "CountriesDomain", swiftSettings: swiftSettings),
    .testTarget(name: "CountriesDomainTests", dependencies: ["CountriesDomain"], swiftSettings: swiftSettings),
  ]
)
