//
//  ServerPeerAuthenticationInterceptor.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import GRPCCore
import GRPCNIOTransportHTTP2Posix
import X509

/// Identifies the process behind an RPC from its mTLS client certificate, without requiring one.
///
/// This is the other kind of caller. A person proves who they are with a bearer token, which
/// ``ServerTokenAuthenticationInterceptor`` reads; a process proves it with the certificate it
/// presented at the handshake, which this reads. The two are independent, because a request can
/// carry both — a service relaying a person's call arrives with its own certificate *and* the
/// person's token — and each binds its own task-local.
///
/// The transport has already checked that the certificate chains to the trust roots by the time
/// this runs, so what remains is to say *who* it names: `identify` reads the certificate and
/// returns the app's idea of a peer, or `nil` for a peer this service has no name for. The
/// certificate's names are the transport's concern and the peer type is the app's, so neither
/// is decided here. What a peer is then allowed to do is the destination's decision, made where
/// the service is built — a certificate proves a credential, never a permission.
///
/// A call with no certificate, or from a peer `identify` declines, arrives unbound rather than
/// refused. That is the same split as the token interceptor: identifying a caller and requiring
/// one are not the same job, and the handler that needs a process insists on one. It is not the
/// same as a token that fails to verify, which is refused: an unlisted certificate is a valid
/// peer this service simply does not admit, and the transport already rejected the invalid ones.
///
/// It needs the NIO transport because the certificate is transport specific — `GRPCCore` alone
/// cannot see it. Only the Posix HTTP/2 transport exposes one; on any other transport every call
/// arrives unbound.
public struct ServerPeerAuthenticationInterceptor<Peer: Sendable>: ServerInterceptor {
    private let peer: TaskLocal<Peer?>
    private let identify: @Sendable (Certificate) -> Peer?

    /// - Parameters:
    ///   - peer: The app's task-local, bound for the length of each call whose certificate
    ///     `identify` recognises.
    ///   - identify: Names the peer from its leaf certificate, or returns `nil` for one this
    ///     service does not admit.
    public init(
        peer: TaskLocal<Peer?>,
        identify: @escaping @Sendable (Certificate) -> Peer?
    ) {
        self.peer = peer
        self.identify = identify
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next:
            @Sendable (
                _ request: StreamingServerRequest<Input>,
                _ context: ServerContext
            ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard
            let transport = context.transportSpecific as? HTTP2ServerTransport.Posix.Context,
            let certificate = transport.peerCertificate,
            let identified = identify(certificate)
        else {
            return try await next(request, context)
        }

        return try await peer.withValue(identified) {
            return try await next(request, context)
        }
    }
}
