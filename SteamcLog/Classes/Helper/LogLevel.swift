//
//  LogLevel.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-20.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import XCGLogger

public enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warn
    case error
    case fatal
    case none

    internal var xcgLevel: XCGLogger.Level {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        case .fatal: return .severe
        case .none: return .none
        }
    }
}
