// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "CountriesUI",
  defaultLocalization: "en",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "CountriesUI", targets: ["CountriesUI"]),
  ],
  dependencies: [
    .package(path: "../CountriesDomain"),
  ],
  targets: [
    .target(
      name: "CountriesUI",
      dependencies: ["CountriesDomain"],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "CountriesUITests",
      dependencies: ["CountriesUI", "CountriesDomain"],
      swiftSettings: swiftSettings
    ),
  ]
)
