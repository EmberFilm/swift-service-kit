// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "swift-service-kit",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
        .library(
            name: "PostgresPersistence",
            targets: ["PostgresPersistence"]
        ),
        .library(
            name: "PersistenceTesting",
            targets: ["PersistenceTesting"]
        ),
        .library(
            name: "Authentication",
            targets: ["Authentication"]
        ),
        .library(
            name: "JWTAuthentication",
            targets: ["JWTAuthentication"]
        ),
        .library(
            name: "SPIFFEAuthentication",
            targets: ["SPIFFEAuthentication"]
        ),
        .library(
            name: "GRPCAuthentication",
            targets: ["GRPCAuthentication"]
        ),
        .library(
            name: "HTTPAuthentication",
            targets: ["HTTPAuthentication"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.15.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.0"),
        // Below 5.7.0 on purpose: 5.7.0 compiles with `treatAllWarnings(as: .error)`, and Xcode
        // passes `-suppress-warnings` to every dependency, which the compiler refuses to combine.
        // `swift build` passes on 5.7.0; the Xcode build does not. Revisit when jwt-kit drops the
        // setting or Xcode stops adding the flag.
        .package(url: "https://github.com/vapor/jwt-kit.git", "5.3.0"..<"5.7.0"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.9.1"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.20.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.26.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.2.0"),
    ],
    targets: [
        .target(
            name: "Persistence"
        ),
        .target(
            name: "PostgresPersistence",
            dependencies: [
                "Persistence",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
        // For a use-case test: a `Database` with no transaction and a fixed scope. Its own product
        // so a service's core target never links it by accident.
        .target(
            name: "PersistenceTesting",
            dependencies: ["Persistence"]
        ),
        // The shapes: what a signer and a verifier are, and the two contexts a call binds. Depends on
        // no token format, so a domain target links it without pulling a JWT library in behind it.
        .target(
            name: "Authentication",
            dependencies: [
                .product(name: "X509", package: "swift-certificates"),
            ]
        ),
        // The JWT implementation of the signer and verifier, over jwt-kit. The one place the kit
        // knows what a token looks like on the wire.
        .target(
            name: "JWTAuthentication",
            dependencies: [
                "Authentication",
                .product(name: "JWTKit", package: "jwt-kit"),
            ]
        ),
        // The SPIFFE implementation of the peer identifier. The one place the kit knows what a
        // workload identity looks like on a certificate.
        .target(
            name: "SPIFFEAuthentication",
            dependencies: [
                "Authentication",
                .product(name: "X509", package: "swift-certificates"),
            ]
        ),
        // Binds both callers: the person from the bearer token, the process from the mTLS
        // certificate. It needs the NIO transport because the peer certificate is transport
        // specific — `GRPCCore` alone cannot see it.
        .target(
            name: "GRPCAuthentication",
            dependencies: [
                "Authentication",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2Posix", package: "grpc-swift-nio-transport"),
                .product(name: "X509", package: "swift-certificates"),
            ]
        ),
        .target(
            name: "HTTPAuthentication",
            dependencies: [
                "Authentication",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
