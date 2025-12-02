// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Macros",
    platforms: [.iOS(.v16), .macOS(.v10_15)],
    products: [
      .library(
        name: "Dependency",
        targets: ["Dependency"]
      ),
    ],
    dependencies: [
      .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
    ],
    targets: [
      .executableTarget(
        name: "Playground",
        dependencies: ["Dependency"],
        path: "Playground/Sources"
      ),
      .target(
        name: "Utils",
        dependencies: [
          .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
          .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ],
        path: "Utils/Sources"
      ),
      // MARK: - Dependency

      .target(
        name: "Dependency",
        dependencies: ["DependencyMacros"],
        path: "Dependency/Interface"
      ),
      .macro(
        name: "DependencyMacros",
        dependencies: ["Utils"],
        path: "Dependency/Implementation"
      ),
      .testTarget(
        name: "DependencyMacrosTests",
        dependencies: [
          "DependencyMacros",
          "Utils",
          .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
        ],
        path: "Dependency/Tests"
      )
    ]
)
