//
//  SteamcLogLevel.swift
//  SteamcLog
//
//  Created by Brendan Lensink on 2019-11-22.
//

import Foundation
import XCGLogger

public enum SteamcLogLevel: Int {
    case verbose
    case debug
    case info
    case warn
    case nonfatal
    case fatal

    internal var xcgLevel: XCGLogger.Level {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .nonfatal: return .error
        case .fatal: return .severe
        }
    }
}
