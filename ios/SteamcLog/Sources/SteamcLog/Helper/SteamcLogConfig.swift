//
//  SteamcLogConfig.swift
//  
//
//  Created by Brendan Lensink on 2019-12-05.
//

public struct SteamcLogConfig {
    /// Global log threshold, logs under this level will be ignored
    var threshold: SteamcLogLevel = .info

    /// By default we log to the console using a custom logging destination, so ignore this one
    var includeDefaultXCGDestinations = false

    var identifier = "steamclog" // TODO: Should this be bundle name or something? Do we have access to that from inside the package?

    var crashlyticsAppKey = ""

    public init(threshold: SteamcLogLevel = .info, includeDefaultXCGDestinations: Bool = false, identifier: String = "steamclog") {
        self.threshold = threshold
        self.includeDefaultXCGDestinations = includeDefaultXCGDestinations
        self.identifier = identifier
    }
}
