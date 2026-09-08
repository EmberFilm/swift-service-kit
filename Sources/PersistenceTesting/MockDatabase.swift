//
//  MockDatabase.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import Persistence

/// A ``Database`` that hands every unit of work the same scope, with no transaction around it.
///
/// A use case is tested by giving it repositories it can inspect afterwards, and this is how the
/// use case reaches them: the scope is built once from those repositories and handed over on each
/// call, so the test sees exactly what the use case did. Nothing is rolled back on a throw,
/// because there is nothing to roll back — the test asserts against the repositories directly.
///
/// ```swift
/// let repository = MockUserRepository()
/// let database = MockDatabase(scope: MockUsersScope(userRepository: repository))
/// let user = try await CreateUserUseCase(database: database)(input: input)
/// #expect(try await repository.find(id: user.id) == user)
/// ```
public struct MockDatabase<Scope: Sendable>: Database {
    public let scope: Scope

    public init(scope: Scope) {
        self.scope = scope
    }

    public func withTransaction<T: Sendable>(
        _ operation: @Sendable (Scope) async throws -> T
    ) async throws -> T {
        try await operation(scope)
    }
}
