//
//  MockTokenVerifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import UserAuthentication

/// A ``TokenVerifier`` that answers from a table instead of a key.
///
/// A handler test wants to say "this request carries a token for this user" and nothing about
/// signatures; minting a real key pair per test is slow and proves nothing the test is about.
/// The table maps the strings a test will send as bearer tokens to the payloads they stand for.
/// A token that is not in it fails to verify, so the same test can cover the refusal path.
///
/// ```swift
/// let verifier = MockTokenVerifier(["admin-token": AppToken(role: .admin)])
/// ```
public struct MockTokenVerifier<Payload: Sendable>: TokenVerifier {
    public struct UnknownToken: Error, Equatable {
        public let token: String
    }

    private let payloads: [String: Payload]

    public init(_ payloads: [String: Payload]) {
        self.payloads = payloads
    }

    public func verify(token: String) async throws -> Payload {
        guard let payload = payloads[token] else {
            throw UnknownToken(token: token)
        }

        return payload
    }
}
