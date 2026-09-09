//
//  TokenAuthenticationMiddleware.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Hummingbird
import HummingbirdAuth
import ServiceContextModule
import UserAuthentication

/// Resolves the caller from the request's bearer token and makes them available for
/// the rest of the request.
///
/// It does both halves of that in one pass. The payload goes on the request context as its
/// `identity`, where `IsAuthenticatedMiddleware` and the route handlers read it, and it goes into
/// the task's `ServiceContext` alongside the encoded token, which is what lets a handler call
/// another service as the same caller without threading the token through every signature it
/// passes through on the way.
///
/// That is why this is a `RouterMiddleware` rather than an `AuthenticatorMiddleware`:
/// `authenticate` returns before the route handler runs, leaving no scope in which to bind a task
/// local the handler would still see. `handle` wraps the rest of the chain, so it has one.
///
/// It identifies the caller without requiring there to be one. A request carrying no token
/// continues anonymously, which is what an open route needs — logging in and registering mint the
/// first token and have no caller yet. Turning away an anonymous request is
/// `IsAuthenticatedMiddleware`'s job, added to the routes that are protected.
/// ``ServerTokenAuthenticationInterceptor`` draws the same line for gRPC.
public struct TokenAuthenticationMiddleware<Context>: RouterMiddleware where Context: AuthRequestContext {
    private let verifier: any TokenVerifier<Context.Identity>

    /// - Parameter verifier: Reads the token with the public key.
    public init(verifier: any TokenVerifier<Context.Identity>) {
        self.verifier = verifier
    }

    /// Passes a request with no token straight through, and refuses one whose token does not
    /// verify rather than reading it as anonymous.
    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let token = request.headers.bearer?.token else {
            return try await next(request, context)
        }

        let payload = try await verify(token)

        var context = context
        context.identity = payload

        var serviceContext = ServiceContext.current ?? .topLevel
        serviceContext[UserAuthenticationKey<Context.Identity>.self] = UserAuthenticationContext(payload: payload, token: token)

        return try await ServiceContext.withValue(serviceContext) {
            return try await next(request, context)
        }
    }

    /// The rejection is an `HTTPError` rather than the verification error, which carries no status
    /// and would be reported as a server fault — the wrong answer for the most ordinary request a
    /// client makes: one holding a token that has expired.
    private func verify(_ token: String) async throws -> Context.Identity {
        do {
            return try await verifier.verify(token: token)
        } catch {
            throw HTTPError(.unauthorized, message: "Invalid or expired token.")
        }
    }
}
