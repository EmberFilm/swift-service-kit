//
//  Session.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// The session a unit of work runs under — who is calling, as variables a policy can read.
///
/// Supplying one is how an app opts into row-level security: ``PostgresDatabase`` asks it as each
/// transaction begins and sets what it returns. An app whose tables carry no policies supplies
/// none and the question is never asked.
///
/// The app knows what a caller is; this package knows how to configure a session. The caller is
/// read from ambient context, so a session is built once at startup and still answers per request:
///
/// ```swift
/// struct CallerSession: Session {
///     @SessionBuilder
///     var variables: [SessionVariable] {
///         if let payload = ServiceContext.current?.caller?.payload {
///             SessionVariable.callerRole(payload.role)
///             SessionVariable.callerUserID(payload.userID)
///         }
///     }
/// }
/// ```
public protocol Session: Sendable {
    @SessionBuilder var variables: [SessionVariable] { get }
}
