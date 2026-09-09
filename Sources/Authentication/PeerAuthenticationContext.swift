//
//  PeerAuthenticationContext.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import X509

/// What one call proved about the process behind it, bound to the task for the length of that
/// call.
///
/// The counterpart of ``UserAuthenticationContext``. A person proves who they are with a bearer
/// token, and that context carries the verified payload and the token; a process proves it with
/// the mTLS certificate it presented, and this one carries the app's idea of the peer and the
/// certificate that named it. Both are carried because they serve different readers: a handler
/// authorizes against the peer, and anything that needs more than a name — the certificate's
/// expiry, its other names — has the certificate.
///
/// Like `UserAuthenticationContext`, it declares no task-local of its own, because a generic type
/// cannot hold a stored static. The app declares one and hands it to the peer interceptor:
///
/// ```swift
/// enum Caller {
///     @TaskLocal static var service: PeerAuthenticationContext<ServicePrincipal>?
/// }
///
/// ServerPeerAuthenticationInterceptor(peer: Caller.$service) { certificate in
///     ServicePrincipal(certificate: certificate)
/// }
/// ```
///
/// A request can carry both a certificate and a token — a service relaying a person's call — so
/// the two contexts are bound independently, and a handler reads whichever it is written for.
public struct PeerAuthenticationContext<Peer: Sendable>: Sendable {
    public let peer: Peer
    public let certificate: Certificate

    public init(peer: Peer, certificate: Certificate) {
        self.peer = peer
        self.certificate = certificate
    }
}
