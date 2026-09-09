//
//  UserAuthenticationContext.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

/// What one call proved about the person behind it, bound to the task for the length of that call.
///
/// The counterpart of ``PeerAuthenticationContext``, which is the same for a process and its
/// certificate. The `Payload` is the verified token as the app declares it, and `token` is the encoded form
/// that proved it. Both are carried because they serve different readers: a handler authorizes
/// against the payload, and ``ClientTokenPropagationInterceptor`` resends the token when the handler
/// calls another service as the same caller.
///
/// The app declares where it lives, with a task-local, and hands that to the interceptors the
/// same way it hands them the verifier. A generic type cannot hold a stored static, which is why
/// the declaration is the app's rather than this type's:
///
/// ```swift
/// enum Caller {
///     @TaskLocal static var current: UserAuthenticationContext<AppToken>?
/// }
///
/// ServerTokenAuthenticationInterceptor(verifier: verifier, authentication: Caller.$current)
/// ```
///
/// A handler then reads `Caller.current`, and a test binds one with `Caller.$current.withValue`.
/// Whether it is `nil` is not a failure: the interceptors identify a caller without requiring
/// one, so a handler that needs a caller reads it and refuses when nothing is bound. The type
/// itself carries no roles or permissions; those belong to the payload.
public struct UserAuthenticationContext<Payload: Sendable>: Sendable {
    public let payload: Payload
    public let token: String

    public init(payload: Payload, token: String) {
        self.payload = payload
        self.token = token
    }
}
