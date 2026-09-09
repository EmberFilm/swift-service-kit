//
//  ServerTokenAuthenticationInterceptor.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import GRPCCore
import ServiceContextModule
import UserAuthentication

/// Identifies the caller of an RPC from its bearer token, without requiring there to be one.
///
/// Apply it to every RPC that takes a token. It puts a ``UserAuthenticationContext`` in the task's
/// `ServiceContext` when a token is present and leaves the context untouched when there is
/// none, which is what an unprotected RPC needs — registration and login mint the first token
/// and have no caller yet. Insisting on a caller is a separate decision, left to the handler
/// that needs one: it reads the context and refuses with
/// `RPCError(code: .unauthenticated)` when nothing is bound. That is the same split as
/// ``TokenAuthenticationMiddleware`` and `IsAuthenticatedMiddleware` on the HTTP side — identifying a caller
/// and requiring one are not the same job.
///
/// A token that is present but does not verify is refused rather than read as anonymous: absent and
/// invalid are not the same thing, and downgrading the second would turn an expired token into a
/// silent loss of privileges on an unprotected RPC.
///
/// The encoded token is bound alongside the payload because a handler has no way to reach it:
/// `ServerContext` carries the method descriptor and the peers, not the request metadata.
/// ``ClientTokenPropagationInterceptor`` reads it back when the handler calls another service.
public struct ServerTokenAuthenticationInterceptor<Payload: Sendable>: ServerInterceptor {
    private let verifier: any TokenVerifier<Payload>

    /// - Parameter verifier: Reads the token with the public key.
    public init(verifier: any TokenVerifier<Payload>) {
        self.verifier = verifier
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next:
            @Sendable (
                _ request: StreamingServerRequest<Input>,
                _ context: ServerContext
            ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let token = request.metadata.bearer else {
            return try await next(request, context)
        }

        let payload = try await verify(token)

        var serviceContext = ServiceContext.current ?? .topLevel
        serviceContext[UserAuthenticationKey<Payload>.self] = UserAuthenticationContext(payload: payload, token: token)

        return try await ServiceContext.withValue(serviceContext) {
            return try await next(request, context)
        }
    }

    private func verify(_ token: String) async throws -> Payload {
        do {
            return try await verifier.verify(token: token)
        } catch {
            throw RPCError(code: .unauthenticated, message: "Invalid or expired token.")
        }
    }
}
