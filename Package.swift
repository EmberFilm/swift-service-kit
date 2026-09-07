// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "swift-persistence",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
        .library(
            name: "PersistencePostgres",
            targets: ["PersistencePostgres"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.15.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.1"),
    ],
    targets: [
        .target(
            name: "Persistence"
        ),
        .target(
            name: "PersistencePostgres",
            dependencies: [
                "Persistence",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
