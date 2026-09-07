//
//  SessionBuilder.swift
//  swift-persistence
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// Builds the ``SessionVariable``s a unit of work runs under.
///
/// What a caller gets is rarely a fixed list — a role always, a user id only when the caller is a
/// person, a tenant only on a tenanted route. Written as an array that is conditionally appended
/// to, that logic reads as plumbing; written as a builder, it reads as the rule:
///
/// ```swift
/// @SessionBuilder
/// var variables: [any SessionVariable] {
///     if let identity = IdentityContext.current?.identity {
///         CallerRole(identity.role)
///
///         if let userID = identity.userID {
///             CallerUserID(userID)
///         }
///     }
/// }
/// ```
///
/// Producing nothing is a legitimate result, not an edge case: a caller who presented no credential
/// sets no variables, and policies that test for one then admit no rows.
@resultBuilder
public enum SessionBuilder {
    public static func buildExpression(_ expression: any SessionVariable) -> [any SessionVariable] {
        [expression]
    }

    public static func buildExpression(_ expression: [any SessionVariable]) -> [any SessionVariable] {
        expression
    }

    public static func buildBlock(_ components: [any SessionVariable]...) -> [any SessionVariable] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any SessionVariable]?) -> [any SessionVariable] {
        component ?? []
    }

    public static func buildEither(first component: [any SessionVariable]) -> [any SessionVariable] {
        component
    }

    public static func buildEither(second component: [any SessionVariable]) -> [any SessionVariable] {
        component
    }

    public static func buildArray(_ components: [[any SessionVariable]]) -> [any SessionVariable] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(
        _ component: [any SessionVariable]
    ) -> [any SessionVariable] {
        component
    }
}
