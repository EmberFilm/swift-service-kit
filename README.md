# swift-persistence

How a unit of work reaches its storage, and nothing else. It holds no domain types and knows
nothing about the app around it — you bring your own scopes and repositories.

Nothing here assumes a service, a transport, or a network. A CLI and an app get the same benefit as
an RPC server: the code that does the work never holds a connection.

```swift
.package(url: "https://github.com/EmberFilm/swift-persistence.git", from: "0.1.0"),
```

## Products

| Product | Depends on | For |
| --- | --- | --- |
| `Persistence` | — | `Database` — the transaction boundary and the scope it hands over. |
| `PersistencePostgres` | `Persistence`, PostgresNIO | `PostgresDatabase`, `PostgresScope`, `Session`, `SessionVariable`, `SessionBuilder`. |

`Persistence` carries no dependencies at all, so a domain target links it without pulling a
database driver in behind it. Only the persistence target links `PersistencePostgres`.

## Database

```swift
public protocol Database<Scope>: Sendable {
    associatedtype Scope: Sendable

    func withTransaction<T: Sendable>(
        _ operation: @Sendable (Scope) async throws -> T
    ) async throws -> T
}
```

A **scope** is what one unit of work may reach — the repositories, and nothing else. The domain
declares one scope per use case; a use case is generic over its database and constrains the scope,
so it can only reach what it asked for, and the compiler is what says so rather than a review.

```swift
// Domain layer — no driver in sight.
package protocol PublishPostUseCaseScope: Sendable {
    var postRepository: any PostRepository { get }
}

package struct PublishPostUseCase<DatabaseType>: PublishPostUseCaseProtocol
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
// Persistence layer — one type, satisfying every scope the app has.
package struct PostgresAppScope: PostgresScope, PublishPostUseCaseScope, ListPostsUseCaseScope {
    package let postRepository: any PostRepository

    package init(connection: PostgresConnection, logger: Logger) {
        self.postRepository = PostgresPostRepository(connection: connection, logger: logger)
    }
}
```

The connection never leaves the scope, so no use case can hold one past the end of its work.
Substituting a fake in a test needs no seam invented for testing — it is the same seam the
composition root uses:

```swift
struct MockDatabase<Scope: Sendable>: Database {
    let scope: Scope

    func withTransaction<T: Sendable>(_ operation: @Sendable (Scope) async throws -> T) async throws -> T {
        try await operation(scope)
    }
}
```

### Why there is no connection path

`withTransaction` is the only entry point, deliberately. Under row-level security the caller is set
on the transaction and the policy reads it from there, so a read outside one would arrive anonymous
— and would not fail, it would come back empty. An app with no policies pays a transaction it did
not need; an app with them cannot forget.

Every mature stack lands here: SQLAlchemy autobegins a transaction for every statement, Prisma's
row-level-security extension wraps each query in one, and the Go guidance is simply never to set
session state on a bare pooled connection. Spring keeps a read/write distinction, but as
`@Transactional(readOnly: true)` versus `@Transactional` — both transactions.

## Sessions and row-level security

An app opts into row-level security by supplying a `Session`. With one, `PostgresDatabase` sets its
variables on every transaction it opens; without one, the transactions simply set none.

```swift
struct CallerSession: Session {
    @SessionBuilder
    var variables: [any SessionVariable] {
        if let caller = CallerContext.current {
            CallerRole(caller.role)

            if let userID = caller.userID {
                CallerUserID(userID)
            }
        }
    }
}

PostgresDatabase<PostgresAppScope>(
    client: postgresClient,
    session: CallerSession(),
    logger: logger
)
```

The session is a named role rather than a closure because it is the app's half of a two-part
contract: the app knows what a caller is, the database knows how to configure a session, and
neither needs the other's business. The caller itself comes from ambient context, so it is built
once at startup and still answers per request — asked as each unit of work begins, because the
caller differs from one call to the next while the database does not.

`SessionVariable` is a protocol, so each variable is a named type in the app that owns it — the
name is declared once, beside the meaning of its value, rather than being a string repeated at the
call site:

```swift
struct CallerRole: SessionVariable {
    let name = "app.caller_role"
    let value: String

    init(_ role: UserRole) {
        self.value = role.rawValue
    }
}
```

Each is applied with `set_config(name, value, true)` — one call, one variable. `set_config` rather
than `SET LOCAL` because it takes bound parameters, so nothing is spliced into SQL and a caller
cannot smuggle a value in; `SET LOCAL` accepts none, and outside a transaction it does not even
warn loudly enough to notice. The trailing `true` is what makes it transaction-local: it reverts at
commit *and* at rollback, so a pooled connection carries nothing over to its next borrower.

Returning nothing is a legitimate answer rather than an edge case: an anonymous caller sets no
variables, and policies that test for one then admit no rows — which is what an unauthenticated
transaction deserves.

Whether to supply a session is a fact about the schema rather than about who is calling, which is
why it is decided once at the composition root and is the same for every caller.

## Requirements

Swift 6.1+, macOS 15+ or Linux. Depends on [PostgresNIO](https://github.com/vapor/postgres-nio)
and [swift-log](https://github.com/apple/swift-log).
