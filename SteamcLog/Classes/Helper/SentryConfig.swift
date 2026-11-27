//
//  SentryConfig.swift
//  
//
//  Created by Brendan on 2022-03-21.
//

import Foundation

public struct SentryConfig: Sendable {
    /// Sentry project specific key. Found here: https://docs.sentry.io/platforms/cocoa/?platform=swift
    /// Set this key to an empty string to not report logs to Sentry.
    let key: String

    /// Toggles Sentry attaching stack traces to errors. Default is true.
    let attachStackTrace: Bool

    /// Toggles Sentry auto session tracking. Default is false.
    /// More info here: https://docs.sentry.io/platforms/cocoa/?platform=swift#release-health
    let autoSessionTracking: Bool

    /// Debug mode for Sentry SDK. Default is false.
    /// More info here: https://docs.sentry.io/error-reporting/configuration/?platform=swift#debug
    let debug: Bool

    /// Sets the percentage of the tracing data that is collected by Sentry. Default is 0.
    let tracesSampleRate: NSNumber

    /// Sets Sentry's `environment`. Default is `debug` in debug builds and `prod` otherwise.
    let environment: String

    #if DEBUG
    public static let defaultEnvironment = "debug"
    #else
    public static let defaultEnvironment = "prod"
    #endif

    /*
     * Create a new Sentry Configuration to use.
     *
     * - Parameters:
     *   - key: Sentry project key, needed to initialize SentrySDK.
     *   - attachStackTrace: Toggles Sentry attaching stack traces to errors. Default is true.
     *   - autoSessionTracking: Enable SentrySDK auto session tracking. Default is false.
     *   - debug: Enable debug mode for SentrySDK. Default is false.
     *   - tracesSampleRate: Sets the percentage of the tracing data that is collected by Sentry.
     *   - environment: Sets Sentry's `environment`. Default is `debug` in debug builds and `prod` otherwise.
     */
    public init(
            key: String,
            attachStacktrace: Bool = true,
            autoSessionTracking: Bool = true,
            debug: Bool = false,
            tracesSampleRate: NSNumber = 0.0,
            environment: String = SentryConfig.defaultEnvironment) {
        self.key = key
        self.attachStackTrace = attachStacktrace
        self.autoSessionTracking = autoSessionTracking
        self.debug = debug
        self.tracesSampleRate = tracesSampleRate
        self.environment = environment
    }
}
