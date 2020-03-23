//
//  LogLevelPreset.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public enum LogLevelPreset {
    /// Disk: verbose, system: verbose, remote: none, analytics: disabled
    case firehose
    /// Disk: none, system: debug, remote: none, analytics: disabled
    case develop
    /// Disk: verbose, system: none, remote: warn, analytics: enabled
    case releaseAdvanced
    /// Disk: none, system: none, remote: warn, analytics: enabled
    case release

    case custom(globalLevel: LogLevel, systemLevel: LogLevel, fileLevel: LogLevel, crashlyticsLevel: LogLevel, analyticsEnabled: Bool)

    var global: LogLevel {
        switch self {
        case .firehose: return .info
        case .develop: return .info
        case .releaseAdvanced: return .info
        case .release: return .warn
        case .custom(let globalLevel, _, _ , _): return globalLevel
        }
    }

    var crashlytics: LogLevel {
        switch self {
        case .firehose: return .none
        case .develop: return .none
        case .releaseAdvanced: return .warn
        case .release: return .warn
        case .custom(_, let crashlyticsLevel, _ , _): return crashlyticsLevel
        }
    }

    var file: LogLevel {
        switch self {
        case .firehose: return .verbose
        case .develop: return .none
        case .releaseAdvanced: return .verbose
        case .release: return .none
        case .custom(_, _, let fileLevel , _): return fileLevel
        }
    }

    var system: LogLevel {
        switch self {
        case .firehose: return .verbose
        case .develop: return .debug
        case .releaseAdvanced: return .none
        case .release: return .none
        case .custom(_, _, _ , let systemLevel): return systemLevel
        }
    }
  
  var analyticsEnabled: Bool {
        switch self {
        case .firehose: return false
        case .develop: return false
        case .releaseAdvanced: return true
        case .release: return true
        case .custom(_, _, _ , _, let analyticsEnabled): return analyticsEnabled
        }

    static func custom(usingBase base: LogLevelPreset,
                       globalLevel: LogLevel? = nil,
                       systemLevel: LogLevel? = nil,
                       fileLevel: LogLevel? = nil,
                       crashlyticsLevel: LogLevel? = nil) -> LogLevelPreset {
        return .custom(globalLevel: globalLevel ?? base.global,
                       systemLevel: systemLevel ?? base.system,
                       fileLevel: fileLevel ?? base.file,
                       crashlyticsLevel: crashlyticsLevel ?? base.crashlytics)
    }
}

public func ==(lhs: LogLevelPreset, rhs: LogLevelPreset) -> Bool {
    switch (lhs, rhs) {
    case (.firehose, .firehose),
         (.develop, .develop),
         (.releaseAdvanced, .releaseAdvanced),
         (.release, .release):
        return true
    case let (.custom(lhsGlobal, lhsSystem, lhsFile, lhsCrashlytics),
              .custom(rhsGlobal, rhsSystem, rhsFile, rhsCrashlytics)):
        return lhsGlobal == rhsGlobal &&
            lhsSystem == rhsSystem &&
            lhsFile == rhsFile &&
            lhsCrashlytics == rhsCrashlytics
         default:
            return false
    }
}
