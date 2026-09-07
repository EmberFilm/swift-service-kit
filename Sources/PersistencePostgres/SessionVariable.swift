//
//  SessionVariable.swift
//  swift-persistence
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// One `name = value` pair set on the session for the length of a transaction.
///
/// This is how a caller's identity reaches a row-level security policy: the policies read settings
/// like `app.caller_role` from the session, and ``PostgresDatabase`` sets each one
/// transaction-locally at the top of its transaction, so they revert at commit or rollback and a
/// pooled connection carries nothing over to its next borrower.
///
/// Applied with `set_config(name, value, true)` — one call, one variable.
/// `set_config` is used rather than `SET LOCAL` because it takes bound parameters: no value is ever
/// spliced into SQL, and a caller cannot smuggle one. The trailing `true` is what makes it
/// transaction-local; outside a transaction it would apply to that one statement and be discarded,
/// which is why every unit of work here is a transaction.
///
/// A protocol rather than a struct so each variable is a named type in the app that owns it. The name
/// is then declared once, beside the value's meaning, instead of being a string repeated at the
/// call site — and the policy that reads it has something to be found by:
///
/// ```swift
/// struct CallerRole: SessionVariable {
///     let name = "app.caller_role"
///     let value: String
///
///     init(_ role: UserRole) {
///         self.value = role.rawValue
///     }
/// }
/// ```
public protocol SessionVariable: Sendable {
    /// The variable to set, as the policies spell it.
    var name: String { get }

    /// What to set it to, for this caller.
    var value: String { get }
}
