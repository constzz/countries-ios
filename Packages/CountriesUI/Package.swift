// swift-tools-version: 6.2
import PackageDescription

/// Zero warnings: every warning fails the build.
let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "CountriesUI",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "CountriesUI", targets: ["CountriesUI"]),
  ],
  dependencies: [
    .package(path: "../CountriesDomain"),
  ],
  targets: [
    .target(name: "CountriesUI", dependencies: ["CountriesDomain"], swiftSettings: swiftSettings),
    .testTarget(name: "CountriesUITests", dependencies: ["CountriesUI"], swiftSettings: swiftSettings),
  ]
)
