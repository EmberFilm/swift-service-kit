//
//  ClientTokenPropagationInterceptor.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/21/26.
//

import UserAuthentication
import GRPCCore

/// Attaches the calling request's access token to an outgoing RPC.
///
/// This is the other half of ``ServerTokenAuthenticationInterceptor``: that one lifts the token off an
/// incoming call, this one puts it back on the next one, so one token identifies the caller at
/// every service in the chain. It is resent unchanged rather than reissued because only the
/// service that signed it can produce another.
///
/// Register it on the `GRPCClient` rather than per call, so a service cannot forget it.
public struct ClientTokenPropagationInterceptor<Payload: Sendable>: ClientInterceptor {
    private let authentication: TaskLocal<UserAuthenticationContext<Payload>?>

    /// - Parameter authentication: The app's task-local, the one the server side binds.
    public init(authentication: TaskLocal<UserAuthenticationContext<Payload>?>) {
        self.authentication = authentication
    }

    /// Calls made outside a caller's request — startup work, a workflow activity, anything with
    /// no inbound token — go out unauthenticated rather than failing here. A process that must
    /// identify itself on such calls needs a credential of its own, which this interceptor does
    /// not provide.
    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (
            _ request: StreamingClientRequest<Input>,
            _ context: ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        guard let authentication = authentication.get() else {
            return try await next(request, context)
        }

        var request = request
        request.metadata.bearer = authentication.token

        return try await next(request, context)
    }
}
