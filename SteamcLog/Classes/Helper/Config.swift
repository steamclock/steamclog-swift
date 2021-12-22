//
//  Config.swift
//  steamclog
//
//  Created by Brendan on 2020-01-20.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public struct Config {
    /// Global log threshold, logs under this level will be ignored
    internal let logLevel: LogLevelPreset

    /// Identifier used for XCGLogger destinations
    internal let identifier: String // TODO: Should this be bundle name or something? Do we have access to that from inside the package?

    /// Allows customization of auto rotating of log files. By default, file will rotate every 600 seconds.
    internal let autoRotateConfig: AutoRotateConfig

    /// Require that all logged objects conform to Redacted or are all redacted by default.
    @usableFromInline internal let requireRedacted: Bool

    /// Sentry project specific key. Found here: https://docs.sentry.io/platforms/cocoa/?platform=swift
    /// Set this key to an empty string to not report logs to Sentry.
    internal let sentryKey: String

    /// Debug mode for Sentry SDK. Default is false.
    /// More info here: https://docs.sentry.io/error-reporting/configuration/?platform=swift#debug
    internal let sentryDebug: Bool

    /// Toggles Sentry auto session tracking. Default is false.
    /// More info here: https://docs.sentry.io/platforms/cocoa/?platform=swift#release-health
    internal let sentryAutoSessionTracking: Bool

    /// Toggles Sentry attaching stack traces  to errors. Default is true.
    internal let sentryAttachStacktrace: Bool

    /// Toggles the ability to filter out errors from being reported to Sentry
    internal let filtering: FilterOut

    /*
     * Create a new SteamcLog configuration to use.
     *
     * - Parameters:
     *   - sentryKey: Sentry project key, needed to initialize SentrySDK.
     *   - logLevel: The log level presets for each destination. Default is `.develop`.
     *   - requireRedacted: If true, all logged objects must conform to `Redacted` or be redacted by default. Default is false.
     *   - identifier: The indentifier to note logs under. Default is "steamclog".
     *   - autoRotateConfig: Customize when logs are rotated. Defaults to 600 seconds.
     *   - sentryDebug: Enable debug mode for SentrySDK. Default is false.
     *   - sentryAutoSessionTracking: Enably SentrySDK auto session tracking. Default is false.
     */
    public init(
            sentryKey: String,
            logLevel: LogLevelPreset = .debug,
            requireRedacted: Bool = false,
            identifier: String = "steamclog",
            autoRotateConfig: AutoRotateConfig = AutoRotateConfig(),
            sentryDebug: Bool = false,
            sentryAutoSessionTracking: Bool = true,
            sentryAttachStacktrace: Bool = true,
            filtering: @escaping FilterOut = { _ in false }) {
        self.requireRedacted = requireRedacted
        self.logLevel = logLevel
        self.identifier = identifier
        self.autoRotateConfig = autoRotateConfig
        self.sentryKey = sentryKey
        self.sentryDebug = sentryDebug
        self.sentryAutoSessionTracking = sentryAutoSessionTracking
        self.sentryAttachStacktrace = sentryAttachStacktrace
        self.filtering = filtering
    }
}
