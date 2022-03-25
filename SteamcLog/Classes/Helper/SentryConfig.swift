//
//  SentryConfig.swift
//  
//
//  Created by Brendan on 2022-03-21.
//

import Foundation

public struct SentryConfig {
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

    /// Toggles the ability to filter out errors from being reported to Sentry
    let filter: SentryFilter

    /*
     * Create a new Sentry Configuration to use.
     *
     * - Parameters:
     *   - key: Sentry project key, needed to initialize SentrySDK.
     *   - attachStackTrace: Toggles Sentry attaching stack traces to errors. Default is true.
     *   - autoSessionTracking: Enable SentrySDK auto session tracking. Default is false.
     *   - debug: Enable debug mode for SentrySDK. Default is false.
     *   - tracesSampleRate: Sets the percentage of the tracing data that is collected by Sentry.
     *   - filter: Toggles the ability to filter out errors from being reported to Sentry
     */
    public init(
            key: String,
            attachStacktrace: Bool = true,
            autoSessionTracking: Bool = true,
            debug: Bool = false,
            tracesSampleRate: NSNumber = 0.0,
            filter: @escaping SentryFilter = { error in false }) {
        self.key = key
        self.attachStackTrace = attachStacktrace
        self.autoSessionTracking = autoSessionTracking
        self.debug = debug
        self.tracesSampleRate = tracesSampleRate
        self.filter = filter
    }
}
