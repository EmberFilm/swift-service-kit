//
//  SPIFFEPeerIdentifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import PeerAuthentication
import X509

/// A ``PeerIdentifier`` that reads a certificate's ``SPIFFEID``.
///
/// It takes the first URI subject alternative name that parses as a SPIFFE ID in the trust
/// domain it was built for, and ignores every other name on the certificate. A certificate with
/// no such name identifies as nothing: a leaf issued before the URI was added, or one issued by
/// another trust domain the CA happens to have signed.
///
/// An app whose peers are richer than an ID — a name in its own vocabulary, a role looked up by
/// name — wraps this in a `PeerIdentifier` of its own and maps the ID.
public struct SPIFFEPeerIdentifier: PeerIdentifier {
    public let trustDomain: String

    public init(trustDomain: String) {
        self.trustDomain = trustDomain
    }

    public func identify(_ certificate: Certificate) -> SPIFFEID? {
        guard let alternativeNames = try? certificate.extensions.subjectAlternativeNames else {
            return nil
        }

        return alternativeNames
            .lazy
            .compactMap { name -> SPIFFEID? in
                if case .uniformResourceIdentifier(let uri) = name { SPIFFEID(uri: uri) } else { nil }
            }
            .first { $0.trustDomain == trustDomain }
    }
}
