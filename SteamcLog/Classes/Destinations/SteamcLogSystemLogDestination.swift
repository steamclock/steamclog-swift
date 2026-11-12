//
//  SteamcLogSystemLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-21.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import OSLog

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

    /// Writes everything this process has sent to os.log since launch to `url`, replacing what's there.
    /// That includes other libraries' lines, and SteamcLog's own, so they can be read in order.
    /// iOS only lets an app read its current process's entries, so earlier launches aren't available.
    static func dump(to url: URL) throws {
        // ponytail: builds the whole dump in memory. Fine for a single launch's logs, stream to a FileHandle if that grows.
        let lines = try OSLogStore(scope: .currentProcessIdentifier).getEntries().compactMap { entry -> String? in
            guard let log = entry as? OSLogEntryLog else { return nil }
            return "\(LogEntry.dateFormatter.string(from: log.date)) [\(levelName(log.level))] [\(log.sender)] [\(log.subsystem):\(log.category)] > \(log.composedMessage)"
        }
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func levelName(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .debug: return "Debug"
        case .info: return "Info"
        case .notice: return "Notice"
        case .error: return "Error"
        case .fault: return "Fault"
        case .undefined: return "Undefined"
        @unknown default: return "Unknown"
        }
    }
}
