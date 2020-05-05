//
//  Config.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public struct Config {
    /// Global log threshold, logs under this level will be ignored
    var logLevel: LogLevelPreset = .develop

    /// By default we log to the console using a custom logging destination, so ignore this one
    var includeDefaultXCGDestinations = false

    var identifier = "steamclog" // TODO: Should this be bundle name or something? Do we have access to that from inside the package?

    /// Allows customization of auto rotating of log files. By default, file will rotate every 600 seconds.
    let autoRotateConfig: AutoRotateConfig

    /// Require that all logged objects conform to Redacted or are all redacted by default.
    @usableFromInline internal var requireRedacted = false

    /// Don't initialize the crashlytics destination if set to false
    let useCrashlytics = true

    public init(logLevel: LogLevelPreset = .develop, includeDefaultXCGDestinations: Bool = false, identifier: String = "steamclog", autoRotateConfig: AutoRotateConfig = AutoRotateConfig()) {
        self.logLevel = logLevel
        self.includeDefaultXCGDestinations = includeDefaultXCGDestinations
        self.identifier = identifier
        self.autoRotateConfig = autoRotateConfig
    }
}
