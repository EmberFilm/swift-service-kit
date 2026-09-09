//
//  SessionBuilder.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/8/26.
//

/// Builds the ``SessionVariable``s a unit of work runs under.
///
/// What a caller gets is rarely a fixed list — a role always, a user id only when the caller is a
/// person, a tenant only on a tenanted route. Written as an array that is conditionally appended
/// to, that logic reads as plumbing; written as a builder, it reads as the rule. Each variable is
/// spelled with its type, because a leading dot on consecutive lines parses as a method chain:
///
/// ```swift
/// @SessionBuilder
/// var variables: [SessionVariable] {
///     if let payload = ServiceContext.current?.caller?.payload {
///         SessionVariable.callerRole(payload.role)
///         SessionVariable.callerUserID(payload.userID)
///     }
/// }
/// ```
@resultBuilder
public enum SessionBuilder {
    public static func buildExpression(_ expression: SessionVariable) -> [SessionVariable] {
        [expression]
    }

    public static func buildExpression(_ expression: [SessionVariable]) -> [SessionVariable] {
        expression
    }

    public static func buildBlock(_ components: [SessionVariable]...) -> [SessionVariable] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [SessionVariable]?) -> [SessionVariable] {
        component ?? []
    }

    public static func buildEither(first component: [SessionVariable]) -> [SessionVariable] {
        component
    }

    public static func buildEither(second component: [SessionVariable]) -> [SessionVariable] {
        component
    }

    public static func buildArray(_ components: [[SessionVariable]]) -> [SessionVariable] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(
        _ component: [SessionVariable]
    ) -> [SessionVariable] {
        component
    }
}
