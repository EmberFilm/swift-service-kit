//
//  TokenSigner.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/21/26.
//

/// Mints access tokens for the one service that holds the signing key.
///
/// Every other service is configured with the matching verifying key and a ``TokenVerifier``,
/// which reads a token but cannot produce one. A protocol rather than a type so that the token
/// format is a choice made once, in the composition root — `JWTAuthentication` ships the JWT
/// one — and everything that mints a token is written against the payload it mints.
public protocol TokenSigner<Payload>: Sendable {
    associatedtype Payload: Sendable

    func sign(_ payload: Payload) async throws -> String
}
