//
//  PeerIdentifier.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import X509

/// Names the process behind a certificate.
///
/// The peer counterpart of ``TokenVerifier``, and deliberately the only one: a token arrives as an
/// opaque string that nothing has checked, so the token side needs a verifier, a signer to mint
/// with, and an interceptor to resend it. A certificate arrives already verified — the transport
/// checked the chain at the handshake, and a certificate that fails never produces a connection —
/// is issued by a CA outside the process, and is presented by the TLS client on every connection
/// without being asked. What remains for the application is reading who the certificate names,
/// and this is that one operation.
///
/// A protocol rather than a closure so that an identification scheme is a named thing the
/// composition root picks — ``SPIFFEPeerIdentifier`` is the one the kit ships — and so the peer
/// interceptor takes `any PeerIdentifier<Peer>` the way the token interceptor takes
/// `any TokenVerifier<Payload>`.
public protocol PeerIdentifier<Peer>: Sendable {
    associatedtype Peer: Sendable

    /// The peer a certificate names, or `nil` when it names none this identifier recognises.
    func identify(_ certificate: Certificate) -> Peer?
}
