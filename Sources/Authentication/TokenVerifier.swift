//
//  TokenVerifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/21/26.
//

import JWTKit

/// Reads and verifies access tokens with the public key alone.
///
/// Every service other than the one holding the private key is configured with this. It checks
/// the signature and then hands the payload its own `verify(using:)`, so the claims an app chooses
/// to enforce — expiry, issuer, audience — are declared on the payload type rather than here.
public struct TokenVerifier<Payload>: Sendable where Payload: JWTPayload {
    private let keys: JWTKeyCollection

    public init(publicKey: EdDSA.PublicKey) async {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: publicKey)
        self.keys = keys
    }

    public func verify(token: String) async throws -> Payload {
        try await keys.verify(token)
    }
}
