//
//  LogLevelPreset.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public enum LogLevelPreset {
    /// Disk: verbose, system: verbose, remote: none
    case firehose
    /// Disk: none, system: debug, remote: none
    case develop
    /// Disk: verbose, system: none, remote: warn
    case releaseAdvanced
    /// Disk: none, system: none, remote: warn
    case release

    var global: LogLevel {
        switch self {
        case .firehose: return .info
        case .develop: return .info
        case .releaseAdvanced: return .info
        case .release: return .warn
        }
    }

    var crashlytics: LogLevel {
        switch self {
        case .firehose: return .none
        case .develop: return .none
        case .releaseAdvanced: return .warn
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
}
