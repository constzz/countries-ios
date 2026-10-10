// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "CountriesData",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "CountriesData", targets: ["CountriesData"]),
  ],
  dependencies: [
    .package(path: "../CountriesDomain"),
    .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.4.0"),
  ],
  targets: [
    .target(
      name: "CountriesData",
      dependencies: [
        "CountriesDomain",
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      // Codegen inputs (schema and operations); the generated Swift is in Generated/.
      exclude: ["GraphQL"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "CountriesDataTests",
      dependencies: [
        "CountriesData",
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      swiftSettings: swiftSettings
    ),
  ]
)
