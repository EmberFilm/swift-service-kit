//
//  PostgresDatabase.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/8/26.
//

import Logging
import Persistence
import PostgresNIO

/// A Postgres database, optionally configuring each transaction for the caller.
///
/// Supplying a ``Session`` is how an app opts into row-level security: it is asked as each unit of
/// work begins, and the variables it returns are set on that transaction. An app whose tables
/// carry no policies supplies none, and the transactions simply set no variables.
///
/// A use case never reasons about any of this. It asks for a unit of work, and whether that work
/// arrives identified is the composition root's decision — made once, because whether the tables
/// have policies is a fact about the schema rather than about who is calling. Every caller is then
/// treated the same, an anonymous one included: they set no variables, and their transaction
/// still opens.
public struct PostgresDatabase<Scope: PostgresScope>: Database {
    private let client: PostgresClient
    private let session: (any Session)?
    private let logger: Logger

    /// - Parameters:
    ///   - client: The connection pool to borrow from.
    ///   - session: Who is calling, asked as each unit of work begins. Omit it for an app whose
    ///     tables carry no policies.
    ///   - logger: Passed to every query, and to each scope this database builds.
    public init(
        client: PostgresClient,
        session: (any Session)? = nil,
        logger: Logger = .current
    ) {
        self.client = client
        self.session = session
        self.logger = logger
    }

    /// Runs `operation` in a transaction configured for the caller, rolling back if it throws.
    ///
    /// The session is asked as the work begins, because the caller differs from one call to the
    /// next while the database is built once at startup. This type therefore knows how to configure
    /// a session and nothing at all about what a caller is.
    ///
    /// `PostgresTransactionError` is unwrapped to the error that actually caused the rollback, so
    /// a use case catches the domain error its repository threw rather than a wrapper around it.
    public func withTransaction<T: Sendable>(
        _ operation: @Sendable (Scope) async throws -> T
    ) async throws -> T {
        do {
            return try await client.withTransaction(logger: logger) { connection in
                if let session {
                    for variable in session.variables {
                        try await connection.query(
                            "SELECT set_config(\(variable.name), \(variable.value), true)",
                            logger: logger
                        )
                    }
                }

                return try await operation(Scope(connection: connection, logger: logger))
            }
        } catch let error as PostgresTransactionError {
            throw error.beginError ?? error.closureError ?? error.commitError ?? error.rollbackError ?? error
        }
    }
}
