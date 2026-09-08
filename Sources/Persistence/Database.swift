//
//  Database.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/7/26.
//

/// Where a unit of work reaches its storage.
///
/// The `Scope` is what that work may touch — the repositories, and nothing else. A use case
/// declares the scope it needs and receives exactly that, so it cannot reach a repository it did
/// not ask for, and the compiler is what says so rather than a review. It never holds a connection
/// and never names a driver, which is what lets the same use case run against a live database and
/// against a double with no seam invented for testing.
///
/// Every unit of work is a transaction, including a single read. There is no cheaper
/// connection-scoped entry point on purpose: under row-level security the caller is set on the
/// transaction and the policy reads it from there, so a read outside one would arrive anonymous —
/// and would not fail, it would come back empty. An app with no policies pays a transaction it did
/// not need; an app with them cannot forget.
public protocol Database<Scope>: Sendable {
    associatedtype Scope: Sendable

    /// Runs `operation` in a transaction, rolling back if it throws.
    func withTransaction<T: Sendable>(
        _ operation: @Sendable (Scope) async throws -> T
    ) async throws -> T
}
