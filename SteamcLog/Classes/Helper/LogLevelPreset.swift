//
//  LogLevelPreset.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-20.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public enum LogLevelPreset: String, Codable {
    /// Disk: verbose, system: verbose, remote: none, analytics: disabled
    case firehose
    /// Disk: none, system: debug, remote: none, analytics: disabled
    case develop
    /// Disk: verbose, system: none, remote: warn, analytics: enabled
    case releaseAdvanced
    /// Disk: none, system: none, remote: warn, analytics: enabled
    case release

    var global: LogLevel {
        switch self {
        case .firehose: return .info
        case .develop: return .info
        case .releaseAdvanced: return .info
        case .release: return .warn
        }
    }

    var sentry: LogLevel {
        switch self {
        case .firehose: return .none
        case .develop: return .none
        case .releaseAdvanced: return .info
        case .release: return .warn
        }
    }

    var file: LogLevel {
        switch self {
        case .firehose: return .verbose
        case .develop: return .none
        case .releaseAdvanced: return .verbose
        case .release: return .none
        }
    }

    var system: LogLevel {
        switch self {
        case .firehose: return .verbose
        case .develop: return .debug
        case .releaseAdvanced: return .none
        case .release: return .none
        }
    }

    var analyticsEnabled: Bool {
        switch self {
        case .firehose: return false
        case .develop: return false
        case .releaseAdvanced: return true
        case .release: return true
        }
    }
}
