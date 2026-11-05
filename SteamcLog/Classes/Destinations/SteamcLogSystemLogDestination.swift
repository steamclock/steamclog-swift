//
//  SteamcLogSystemLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-21.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import os

class SteamcLogSystemLogDestination: SteamcLogDestination {
    private let logger: Logger

    init(category: String) {
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? category, category: category)
    }

    func write(_ entry: LogEntry) {
        let emoji: String
        let type: OSLogType

        switch entry.level {
        case .verbose, .debug:
            emoji = ""
            type = .debug
        case .info:
            emoji = ""
            type = .info
        case .warn:
            emoji = "⚠️ "
            type = .default
        case .error:
            emoji = "🚫 "
            type = .error
        case .fatal:
            emoji = "🚫 "
            type = .fault
        case .none:
            emoji = ""
            type = .default
        }

        // os.log adds its own timestamp. Messages are marked public because the old NSLog output was never redacted,
        // and SteamcLog's own `Redacted` handling is what keeps sensitive values out of logs.
        let message = "\(emoji)\(entry.formattedWithoutDate)"
        logger.log(level: type, "\(message, privacy: .public)")
    }
}
