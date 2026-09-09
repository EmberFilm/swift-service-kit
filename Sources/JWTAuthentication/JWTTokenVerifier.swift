//
//  JWTTokenVerifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import Authentication
import JWTKit

/// A ``TokenVerifier`` that reads EdDSA-signed JSON Web Tokens with the public key alone.
///
/// It checks the signature and then hands the payload its own `verify(using:)`, so the claims an
/// app chooses to enforce — expiry, issuer, audience — are declared on the payload type rather
/// than here.
public struct JWTTokenVerifier<Payload: JWTPayload>: TokenVerifier {
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
