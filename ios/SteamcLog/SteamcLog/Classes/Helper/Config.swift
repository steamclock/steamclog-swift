//
//  Config.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
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

    public init(logLevel: LogLevelPreset = .develop,
                requireRedacted: Bool = false,
                identifier: String = "steamclog",
                autoRotateConfig: AutoRotateConfig = AutoRotateConfig()) {
        self.requireRedacted = requireRedacted
        self.logLevel = logLevel
        self.identifier = identifier
        self.autoRotateConfig = autoRotateConfig
    }
}
