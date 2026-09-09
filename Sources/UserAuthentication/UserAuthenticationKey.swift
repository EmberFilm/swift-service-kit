//
//  UserAuthenticationKey.swift
//  swift-service-kit
//
//  Created by Zaid Rahhawi on 9/9/26.
//

import ServiceContextModule

/// Where a ``UserAuthenticationContext`` lives for the length of a call: under this key in the
/// task's `ServiceContext`.
///
/// `ServiceContext` is the one task-local the server ecosystem shares — tracing, logging
/// metadata providers and the transports all read and write it — so the caller a request proved
/// travels with everything else that describes that request, and a span or a log line can carry
/// the user without the app wiring anything. The key is generic over the payload for the same
/// reason the interceptors are: the kit does not know what a token says.
///
/// An app reads it as `ServiceContext.current?[UserAuthenticationKey<AppToken>.self]`, and
/// usually adds a property on `ServiceContext` that spells that once. A test binds one with the
/// standard `ServiceContext.withValue`.
public enum UserAuthenticationKey<Payload: Sendable>: ServiceContextKey {
    public typealias Value = UserAuthenticationContext<Payload>

    public static var nameOverride: String? { "user-authentication" }
}
