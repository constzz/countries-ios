// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
  name: "AtlasData",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "AtlasData", targets: ["AtlasData"]),
  ],
  dependencies: [
    .package(path: "../AtlasDomain"),
    .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.4.0"),
  ],
  targets: [
    .target(
      name: "AtlasData",
      dependencies: [
        "AtlasDomain",
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      // Codegen inputs (schema and operations); the generated Swift is in Generated/.
      exclude: ["GraphQL"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "AtlasDataTests",
      dependencies: [
        "AtlasData",
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      // JSON responses captured from the live API.
      resources: [.copy("Fixtures")],
      swiftSettings: swiftSettings
    ),
  ]
)
