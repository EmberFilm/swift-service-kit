//
//  TokenSigner.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 8/21/26.
//

import JWTKit

/// Mints access tokens for the one service that holds the private key.
///
/// Every other service is configured with the matching public key and a ``TokenVerifier``,
/// which reads a token but cannot produce one.
public struct TokenSigner: Sendable {
    private let keys: JWTKeyCollection

    public init(privateKey: EdDSA.PrivateKey) async {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: privateKey)
        self.keys = keys
    }

    public func sign(_ token: some JWTPayload) async throws -> String {
        try await keys.sign(token)
    }
}
