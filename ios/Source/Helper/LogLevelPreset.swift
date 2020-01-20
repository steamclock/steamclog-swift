//
//  LogLevelPreset.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public enum LogLevelPreset {
    /// Disk: verbose, system: none, remote: none
    case test
    /// Disk: verbose, system: verbose, remote: none
    case debug
    /// Disk: verbose, system: info, remote: none
    case develop
    /// Disk: none, system: none, remote: warn
    case release

    var global: LogLevel {
        switch self {
        case .test: return .verbose
        case .debug: return .verbose
        case .develop: return .verbose
        case .release: return .warn
        }
    }

    var crashlytics: LogLevel {
        switch self {
        case .test: return .none
        case .debug: return .none
        case .develop: return .none
        case .release: return .warn
        }
    }

    var file: LogLevel {
        switch self {
        case .test: return .none
        case .debug: return .verbose
        case .develop: return .verbose
        case .release: return .none
        }
    }

    var system: LogLevel {
        switch self {
        case .test: return .none
        case .debug: return .verbose
        case .develop: return .info
        case .release: return .none
        }
    }
}
