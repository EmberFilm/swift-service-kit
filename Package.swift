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
            name: "AuthenticationTesting",
            targets: ["AuthenticationTesting"]
        ),
        .library(
            name: "UserAuthentication",
            targets: ["UserAuthentication"]
        ),
        .library(
            name: "PeerAuthentication",
            targets: ["PeerAuthentication"]
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
            name: "GRPCNIOTransportAuthentication",
            targets: ["GRPCNIOTransportAuthentication"]
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
        .package(url: "https://github.com/apple/swift-service-context.git", from: "1.1.0"),
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
        // The shapes for a person: what a signer and a verifier are, the context a call binds, and
        // the `ServiceContext` key it is bound under. Depends on nothing but swift-service-context,
        // itself dependency-free, so a domain target links it without pulling a token library or
        // a certificate library in behind it.
        .target(
            name: "UserAuthentication",
            dependencies: [
                .product(name: "ServiceContextModule", package: "swift-service-context"),
            ]
        ),
        // The shapes for a process: what an identifier is, the context a call binds, and its key.
        // Its own target because a peer is named by a certificate, and only the services that
        // admit processes should link the certificate library.
        .target(
            name: "PeerAuthentication",
            dependencies: [
                .product(name: "ServiceContextModule", package: "swift-service-context"),
                .product(name: "X509", package: "swift-certificates"),
            ]
        ),
        // For a handler test: a verifier that answers from a table instead of a key. Its own
        // product so a service's production targets never link it by accident.
        .target(
            name: "AuthenticationTesting",
            dependencies: ["UserAuthentication"]
        ),
        // The JWT implementation of the signer and verifier, over jwt-kit. The one place the kit
        // knows what a token looks like on the wire.
        .target(
            name: "JWTAuthentication",
            dependencies: [
                "UserAuthentication",
                .product(name: "JWTKit", package: "jwt-kit"),
            ]
        ),
        // The SPIFFE implementation of the peer identifier. The one place the kit knows what a
        // workload identity looks like on a certificate.
        .target(
            name: "SPIFFEAuthentication",
            dependencies: [
                "PeerAuthentication",
                .product(name: "X509", package: "swift-certificates"),
            ]
        ),
        // Binds the person from the bearer token, on the way in and the way out. Metadata is all
        // it reads, so it depends on `GRPCCore` alone and works on any transport.
        .target(
            name: "GRPCAuthentication",
            dependencies: [
                "UserAuthentication",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
            ]
        ),
        // Binds the process from its mTLS certificate. Its own target, named for the transport,
        // because the certificate is transport specific — only the NIO Posix HTTP/2 transport
        // exposes it — and a service that admits only people should not link that transport
        // through the token interceptors.
        .target(
            name: "GRPCNIOTransportAuthentication",
            dependencies: [
                "PeerAuthentication",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2Posix", package: "grpc-swift-nio-transport"),
            ]
        ),
        .target(
            name: "HTTPAuthentication",
            dependencies: [
                "UserAuthentication",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
