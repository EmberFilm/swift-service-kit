//
//  SPIFFEID.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

/// A workload identity of the form `spiffe://<trust-domain><path>`.
///
/// The name a certificate carries for the process that holds it, as a URI subject alternative
/// name, in the shape the SPIFFE standard gives it. It is a URI rather than one of the
/// certificate's DNS names because the two are different jobs: a DNS name is what a client
/// dials and verifies, and a process is dialled as different names in different environments;
/// the SPIFFE ID is the process's name in every one of them, and nothing else in the certificate
/// looks like it.
public struct SPIFFEID: Hashable, Sendable {
    /// The issuer's namespace — `emberfilm` in `spiffe://emberfilm/billing-worker`.
    public let trustDomain: String

    /// The workload within it, with its leading slash — `/billing-worker`.
    public let path: String

    public init(trustDomain: String, path: String) {
        self.trustDomain = trustDomain
        self.path = path
    }

    /// Parses `spiffe://<trust-domain><path>`, or fails for anything else.
    public init?(uri: String) {
        let scheme = "spiffe://"

        guard uri.hasPrefix(scheme) else {
            return nil
        }

        let rest = uri.dropFirst(scheme.count)

        guard let slash = rest.firstIndex(of: "/"), rest.startIndex < slash else {
            return nil
        }

        self.init(trustDomain: String(rest[..<slash]), path: String(rest[slash...]))
    }

    public var uri: String {
        "spiffe://\(trustDomain)\(path)"
    }
}
