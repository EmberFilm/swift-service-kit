//
//  PostgresScope.swift
//  swift-persistence
//
//  Created by Zaid Rahhawi on 9/7/26.
//

import Logging
import PostgresNIO

/// A scope ``PostgresDatabase`` knows how to build.
///
/// The initializer is where an app names the repositories one unit of work may reach: it receives
/// the transaction's connection and hands it to each repository it exposes. The connection never
/// leaves the scope, so no use case can hold one past the end of its work.
public protocol PostgresScope: Sendable {
    init(connection: PostgresConnection, logger: Logger)
}
