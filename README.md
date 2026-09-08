# swift-service-kit

The two things every backend service needs and neither framework gives you: a transaction boundary
that hands a use case exactly the repositories it may touch, and a caller you can authorize against.

It holds no domain types. You bring your own claims, your own repositories, your own rules.

```swift
.package(url: "https://github.com/EmberFilm/swift-service-kit.git", from: "0.1.0"),
```

## Products

| Product | Depends on | For |
| --- | --- | --- |
| `Persistence` | — | `Database` — the transaction boundary and the scope it hands over |
| `PostgresPersistence` | PostgresNIO | the Postgres driver, plus row-level-security session variables |
| `Authentication` | jwt-kit | `TokenSigner`, `TokenVerifier`, and `AuthenticationContext<Payload>` |
| `GRPCAuthentication` | grpc-swift-2 | interceptors that bind the caller on the way in and resend the token on the way out |
| `HTTPAuthentication` | hummingbird-auth | the same for Hummingbird |

Link only what you use. `Persistence` and `Authentication` have no transport dependency at all, so
a domain target links them without pulling gRPC or a database driver in behind it.

## Authentication

A caller proves who they are with a bearer token. One service holds the private key and mints
tokens with `TokenSigner`; every other service holds the public key and reads them with
`TokenVerifier`. Tokens are EdDSA-signed.

### The token shape is yours

The kit never reads your claims. It asks only for a `JWTPayload`, and leaves which claims to
enforce to the payload's own `verify(using:)`:

```swift
struct AppToken: JWTPayload {
    let subject: SubjectClaim
    let role: String
    let expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

### What a call proved, for the length of the call

`AuthenticationContext<Payload>` is the verified payload together with the encoded token that
proved it, bound to the task so a handler can reach the caller without threading it through every
signature. The app declares where it lives, with an ordinary task-local:

```swift
enum Caller {
    @TaskLocal static var current: AuthenticationContext<AppToken>?
}
```

A generic type cannot hold a stored static, so the task-local is the app's rather than the kit's.
The interceptors receive it the same way they receive the verifier, and everything else — reading
it, binding it in a test — is the standard library's `TaskLocal` API.

### Binding the caller

The interceptors and middleware identify a caller without requiring one. A request carrying no
token continues anonymously, which is what an open route needs — logging in and registering mint
the first token and have no caller yet. A token that is present but does not verify is refused
rather than read as anonymous, because absent and invalid are not the same thing.

For gRPC:

```swift
let verifier = await TokenVerifier<AppToken>(publicKey: publicKey)

GRPCServer(
    transport: transport,
    services: [service],
    interceptors: [
        ServerTokenAuthenticationInterceptor(verifier: verifier, authentication: Caller.$current)
    ]
)
```

For Hummingbird, on a router whose context conforms to `AuthRequestContext` with `AppToken` as its
identity:

```swift
router.add(middleware: TokenAuthenticationMiddleware<AppRequestContext>(verifier: verifier, authentication: Caller.$current))
```

The Hummingbird middleware sets both the request context's `identity`, which
`IsAuthenticatedMiddleware` and route handlers read, and the task-local.

### Insisting on a caller

Requiring a caller is the handler's decision, not the interceptor's:

```swift
guard let authentication = Caller.current else {
    throw RPCError(code: .unauthenticated, message: "Sign in to continue.")
}

let caller = authentication.payload
```

On the HTTP side, add `IsAuthenticatedMiddleware` to the protected routes.

### Calling onward as the same caller

`ClientTokenPropagationInterceptor` reads the same task-local and puts the token back on the outgoing
call, so one token identifies the caller at every service in the chain. Register it on the
`GRPCClient` so a service cannot forget it:

```swift
GRPCClient(transport: transport, interceptors: [
    ClientTokenPropagationInterceptor(authentication: Caller.$current)
])
```

Calls made outside a caller's request — startup work, a workflow activity — go out unauthenticated
rather than failing. A process that must identify itself on such calls needs a credential of its
own; the kit does not provide one yet.

## Persistence

A **scope** is what one unit of work may reach. The domain declares one per use case, so a use case
can only touch what it asked for and the compiler is what says so:

```swift
package protocol PublishPostUseCaseScope: Sendable {
    var postRepository: any PostRepository { get }
}

package struct PublishPostUseCase<DatabaseType>: Sendable
where DatabaseType: Database, DatabaseType.Scope: PublishPostUseCaseScope {
    private let database: DatabaseType

    package func callAsFunction(input: Input) async throws {
        try await database.withTransaction { scope in
            try await scope.postRepository.publish(input.id)
        }
    }
}
```

```swift
package struct PostgresAppScope: PostgresScope, PublishPostUseCaseScope {
    package let postRepository: any PostRepository

    package init(connection: PostgresConnection, logger: Logger) {
        self.postRepository = PostgresPostRepository(connection: connection, logger: logger)
    }
}
```

The connection never leaves the scope. Substituting a fake needs no seam invented for testing:

```swift
struct MockDatabase<Scope: Sendable>: Database {
    let scope: Scope

    func withTransaction<T: Sendable>(
        _ operation: @Sendable (Scope) async throws -> T
    ) async throws -> T {
        try await operation(scope)
    }
}
```

### Why there is no connection path

`withTransaction` is the only entry point. Under row-level security the caller is set on the
transaction and the policy reads it from there, so a read outside one arrives anonymous — and does
not fail, it comes back empty. An app with no policies pays a transaction it did not need; an app
with them cannot forget.

A `PostgresTransactionError` is unwrapped to the error that caused the rollback, so a use case
catches the domain error its repository threw rather than a wrapper around it.

### Row-level security

Supply a `Session` and every transaction carries the caller's variables, set with
`set_config(name, value, true)` — bound parameters, so nothing is spliced into SQL, and
transaction-local, so they revert at commit *and* rollback and a pooled connection carries nothing
to its next borrower.

The app knows what a caller is; the kit knows how to configure a session. The caller is read from
the task-local, so a session is built once at startup and still answers per request:

```swift
extension SessionVariable {
    static func callerRole(_ role: String) -> Self {
        .init(name: "app.caller_role", value: role)
    }
}

struct CallerSession: Session {
    @SessionBuilder
    var variables: [SessionVariable] {
        if let payload = Caller.current?.payload {
            SessionVariable.callerRole(payload.role)
        }
    }
}

PostgresDatabase<PostgresAppScope>(client: client, session: CallerSession(), logger: logger)
```

Omit the session and the transactions set nothing.

## Requirements

Swift 6.3+, macOS 15+ or Linux.
