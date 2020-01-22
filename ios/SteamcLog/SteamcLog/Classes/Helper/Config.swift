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

    var crashlyticsAppKey = ""

    public init(logLevel: LogLevelPreset = .develop, includeDefaultXCGDestinations: Bool = false, identifier: String = "steamclog") {
        self.logLevel = logLevel
        self.includeDefaultXCGDestinations = includeDefaultXCGDestinations
        self.identifier = identifier
    }
}