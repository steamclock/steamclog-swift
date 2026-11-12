//
//  LogLevel.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-20.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warn
    case error
    case fatal
    case none

    /// Name shown in formatted log lines. Matches the names XCGLogger used, so existing log files read the same.
    internal var name: String {
        switch self {
        case .verbose: return "Verbose"
        case .debug: return "Debug"
        case .info: return "Info"
        case .warn: return "Warning"
        case .error: return "Error"
        case .fatal: return "Severe"
        case .none: return "None"
        }
    }
}
