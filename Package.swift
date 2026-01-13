// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftKaze",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "SwiftKaze",
      targets: ["SwiftKaze"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1")
  ],
  targets: [
    .target(
      name: "SwiftKaze",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]
    ),
    .testTarget(
      name: "SwiftKazeTests",
      dependencies: ["SwiftKaze"]
    ),
  ]
)
