//
//  Session.swift
//  swift-persistence
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// The session a unit of work runs under — who is calling, as variables a policy can read.
///
/// Supplying one is how an app opts into row-level security: ``PostgresDatabase`` asks it as each
/// transaction begins and sets what it returns. An app whose tables carry no policies supplies
/// none and the question is never asked.
///
/// It is a named role rather than a closure because it is the app's half of a two-part contract —
/// the app knows what a caller is, the database knows how to configure a session, and neither
/// needs the other's business. The caller itself is read from ambient context, so a session is
/// built once at startup and still answers per request:
///
/// ```swift
/// struct CallerSession: Session {
///     @SessionBuilder
///     var variables: [any SessionVariable] {
///         if let identity = IdentityContext.current?.identity {
///             CallerRole(identity.role)
///
///             if let userID = identity.userID {
///                 CallerUserID(userID)
///             }
///         }
///     }
/// }
/// ```
///
/// Producing nothing is a legitimate answer, not a failure: a caller who presented no credential
/// sets no variables, and policies that test for one then admit no rows.
public protocol Session: Sendable {
    @SessionBuilder var variables: [any SessionVariable] { get }
}
