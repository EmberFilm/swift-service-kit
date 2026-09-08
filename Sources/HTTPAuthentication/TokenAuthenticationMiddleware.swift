//
//  TokenAuthenticationMiddleware.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/20/26.
//

import Authentication
import Hummingbird
import HummingbirdAuth
import JWTKit

/// Resolves the caller from the request's bearer token and makes them available for
/// the rest of the request.
///
/// It does both halves of that in one pass. The payload goes on the request context as its
/// `identity`, where `IsAuthenticatedMiddleware` and the route handlers read it, and it is bound
/// to the app's task-local alongside the encoded token, which is what lets a handler call another
/// service as the same caller without threading the token through every signature it passes
/// through on the way.
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
public struct TokenAuthenticationMiddleware<Context>: RouterMiddleware where Context: AuthRequestContext, Context.Identity: JWTPayload {
    private let verifier: TokenVerifier<Context.Identity>
    private let authentication: TaskLocal<AuthenticationContext<Context.Identity>?>

    /// - Parameters:
    ///   - verifier: Reads the token with the public key.
    ///   - authentication: The app's task-local, bound for the length of each request that carries a token.
    public init(
        verifier: TokenVerifier<Context.Identity>,
        authentication: TaskLocal<AuthenticationContext<Context.Identity>?>
    ) {
        self.verifier = verifier
        self.authentication = authentication
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
        let authentication = AuthenticationContext(payload: payload, token: token)

        return try await self.authentication.withValue(authentication) {
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
