//
//  PeerAuthenticationKey.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import ServiceContextModule

/// Where a ``PeerAuthenticationContext`` lives for the length of a call: under this key in the
/// task's `ServiceContext`, beside — and independent of — the user's.
///
/// A request can carry both a certificate and a token, a service relaying a person's call, so
/// the two are separate keys rather than one caller with two cases: each interceptor sets its
/// own and neither touches the other's.
public enum PeerAuthenticationKey<Peer: Sendable>: ServiceContextKey {
    public typealias Value = PeerAuthenticationContext<Peer>

    public static var nameOverride: String? { "peer-authentication" }
}
