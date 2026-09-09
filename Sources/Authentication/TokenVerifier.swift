//
//  TokenVerifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/21/26.
//

/// Reads and verifies access tokens with the verifying key alone.
///
/// Every service other than the one holding the signing key is configured with one. A protocol
/// rather than a type so that the interceptors and middleware are written against the payload
/// they bind, not against a token format: `JWTAuthentication` ships the JWT one, and a test
/// hands an interceptor a verifier that returns whatever payload it likes.
public protocol TokenVerifier<Payload>: Sendable {
    associatedtype Payload: Sendable

    func verify(token: String) async throws -> Payload
}
