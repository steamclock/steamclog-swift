//
//  LogLevelPreset.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-20.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public enum LogLevelPreset: String, Codable {

    /// console: verbose, disk: verbose, remote: none
    case debugVerbose

    /// console: debug, disk: debug, remote: none
    case debug

    /// console: none, disk: info, remote: info
    case release

    /// console: none, disk: debug, remote: debug
    case releaseAdvanced

    var global: LogLevel {
        switch self {
        case .debugVerbose: return .info
        case .debug: return .info
        case .release: return .warn
        case .releaseAdvanced: return .info
        }
    }

    var remote: LogLevel {
        switch self {
        case .debugVerbose: return .none
        case .debug: return .none
        case .release: return .info
        case .releaseAdvanced: return .debug
        }
    }

    var disk: LogLevel {
        switch self {
        case .debugVerbose: return .verbose
        case .debug: return .debug
        case .release: return .info
        case .releaseAdvanced: return .debug
        }
    }

    var console: LogLevel {
        switch self {
        case .debugVerbose: return .verbose
        case .debug: return .debug
        case .release: return .none
        case .releaseAdvanced: return .none
        }
    }

    // TODO 2021-09-16: If analytics are by default no longer supported, should we remove this?
    var analyticsEnabled: Bool {
        switch self {
        case .debugVerbose: return false
        case .debug: return false
        case .release: return true
        case .releaseAdvanced: return true
        }
    }
}
