//
//  SessionVariable.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// One `name = value` pair set on the session for the length of a transaction.
///
/// How a caller reaches a row-level security policy: the policy reads `app.caller_role` from the
/// session, and ``PostgresDatabase`` sets it with `set_config(name, value, true)` — bound
/// parameters, so nothing is spliced into SQL, and transaction-local, so it reverts at commit and at
/// rollback rather than following a pooled connection to its next borrower.
///
/// An app declares each variable once, beside the meaning of its value, as a factory on this type:
///
/// ```swift
/// extension SessionVariable {
///     static func callerRole(_ role: UserRole) -> Self {
///         .init(name: "app.caller_role", value: role.rawValue)
///     }
/// }
/// ```
public struct SessionVariable: Sendable {
    let name: String
    let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
