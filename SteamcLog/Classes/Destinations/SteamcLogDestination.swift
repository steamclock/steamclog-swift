//
//  SteamcLogDestination.swift
//  SteamcLog
//
//  Copyright (c) 2026 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// Somewhere log lines can be sent. Attach your own with `SteamcLog.attach(destination:outputLevel:)`.
public protocol SteamcLogDestination: AnyObject {
    func write(_ entry: LogEntry)
}

/// Which log level a destination receives.
public enum DestinationLevel {
    /// Follow the preset's console level, updating whenever `SteamcLog.config` changes.
    case console
    /// Follow the preset's disk level, updating whenever `SteamcLog.config` changes.
    case disk
    /// Follow the preset's remote level, updating whenever `SteamcLog.config` changes.
    case remote
    /// Always use this level, regardless of `SteamcLog.config`.
    case fixed(LogLevel)

    func resolve(_ preset: LogLevelPreset) -> LogLevel {
        switch self {
        case .console: return preset.console
        case .disk: return preset.disk
        case .remote: return preset.remote
        case .fixed(let level): return level
        }
    }
}
