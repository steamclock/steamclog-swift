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

    /// Debug mode for Sentry SDK. Default is false.
    /// More info here: https://docs.sentry.io/error-reporting/configuration/?platform=swift#debug
    let debug: Bool

    /// Toggles Sentry auto session tracking. Default is false.
    /// More info here: https://docs.sentry.io/platforms/cocoa/?platform=swift#release-health
    let autoSessionTracking: Bool

    /// Toggles Sentry attaching stack traces to errors. Default is true.
    let attachStackTrace: Bool

    /// Toggles the ability to filter out errors from being reported to Sentry
    let filter: SentryFilter

    /*
     * Create a new Sentry Configuration to use.
     *
     * - Parameters:
     *   - key: Sentry project key, needed to initialize SentrySDK.
     *   - debug: Enable debug mode for SentrySDK. Default is false.
     *   - autoSessionTracking: Enable SentrySDK auto session tracking. Default is false.
     *   - attachStackTrace: Toggles Sentry attaching stack traces to errors. Default is true.
     *   - filter: Toggles the ability to filter out errors from being reported to Sentry
     */
    public init(
            key: String,
            debug: Bool = false,
            autoSessionTracking: Bool = true,
            attachStacktrace: Bool = true,
            filter: @escaping SentryFilter = { error in false }) {
        self.key = key
        self.debug = debug
        self.autoSessionTracking = autoSessionTracking
        self.attachStackTrace = attachStacktrace
        self.filter = filter
    }
}
