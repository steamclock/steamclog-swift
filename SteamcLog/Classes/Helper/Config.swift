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

    /// Predicate for testing any Error-conforming objects passed in as the associated object at the "error" log level. If true, that specific instance of the error will be downgraded to a warning.
    /// Useful for stoping certain types of failures (network errors, etc) from being logged off device.
    let suppressError: ((Error) -> Bool)?


    /*
     * Create a new SteamcLog configuration to use.
     *
     * - Parameters:
     *   - logLevel: The log level presets for each destination. Default is `.develop`.
     *   - requireRedacted: If true, all logged objects must conform to `Redacted` or be redacted by default. Default is false.
     *   - identifier: The indentifier to note logs under. Default is "steamclog".
     *   - autoRotateConfig: Customize when logs are rotated. Defaults to 600 seconds.
     *   - suppressError: Downgrade some errors to warnings if this test returns true
     */
    public init(
            logLevel: LogLevelPreset = .debug,
            requireRedacted: Bool = false,
            identifier: String = "steamclog",
            autoRotateConfig: AutoRotateConfig = AutoRotateConfig(),
            suppressError: ((Error) -> Bool)? = nil) {
        self.requireRedacted = requireRedacted
        self.logLevel = logLevel
        self.identifier = identifier
        self.autoRotateConfig = autoRotateConfig
        self.suppressError = suppressError
    }
}
