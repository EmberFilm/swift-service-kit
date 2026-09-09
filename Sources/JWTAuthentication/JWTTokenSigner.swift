//
//  JWTTokenSigner.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import Authentication
import JWTKit

/// A ``TokenSigner`` that mints EdDSA-signed JSON Web Tokens.
///
/// Built once, in the composition root of the one service that holds the private key. The
/// payload type is fixed at construction so that a signer mints exactly one shape of token, and
/// a use case that receives an `any TokenSigner<UserPayload>` cannot be handed a signer for
/// anything else.
public struct JWTTokenSigner<Payload: JWTPayload>: TokenSigner {
    private let keys: JWTKeyCollection

    public init(privateKey: EdDSA.PrivateKey) async {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: privateKey)
        self.keys = keys
    }

    public func sign(_ payload: Payload) async throws -> String {
        try await keys.sign(payload)
    }
}
