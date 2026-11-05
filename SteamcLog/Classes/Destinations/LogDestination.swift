//
//  LogDestination.swift
//  SteamcLog
//
//  Copyright (c) 2026 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// A single log line, as handed to each destination.
public struct LogEntry {
    public let level: LogLevel
    public let message: String
    public let date: Date
    public let threadName: String
    public let functionName: String
    public let fileName: String
    public let lineNumber: Int
    public let userInfo: [String: Any]

    /// SteamcLog's own housekeeping lines (app details, file rotation) carry no call site, and are formatted without one.
    let isInternal: Bool

    init(level: LogLevel, message: String, functionName: String = "", fileName: String = "", lineNumber: Int = 0, userInfo: [String: Any] = [:], isInternal: Bool = false) {
        self.level = level
        self.message = message
        self.date = Date()
        self.threadName = LogEntry.currentThreadName()
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.userInfo = userInfo
        self.isInternal = isInternal
    }

    /// `2026-01-01 12:00:00.000 [Info] [main] [File.swift:12] function() > message`
    public var formattedMessage: String {
        "\(LogEntry.dateFormatter.string(from: date)) \(formattedWithoutDate)"
    }

    /// Same as `formattedMessage`, minus the date, for destinations that timestamp lines themselves.
    var formattedWithoutDate: String {
        if isInternal {
            return "[\(level.name)] > \(message)"
        }
        let file = (fileName as NSString).lastPathComponent
        return "[\(level.name)] [\(threadName)] [\(file):\(lineNumber)] \(functionName) > \(message)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static func currentThreadName() -> String {
        if Thread.isMainThread { return "main" }
        if let name = Thread.current.name, !name.isEmpty { return name }
        if let label = String(validatingUTF8: __dispatch_queue_get_label(nil)), !label.isEmpty { return label }
        return String(format: "%p", Thread.current)
    }

    /// `AppName Version: 1.0 Build: 1 PID: 123`
    static var appDetails: String {
        let info = Bundle.main.infoDictionary ?? [:]
        var build = ""
        if let version = info["CFBundleShortVersionString"] as? String { build += "Version: \(version) " }
        if let number = info["CFBundleVersion"] as? String { build += "Build: \(number) " }
        let process = ProcessInfo.processInfo
        return "\(process.processName) \(build)PID: \(process.processIdentifier)"
    }
}

/// Somewhere log lines can be sent. Attach your own with `SteamcLog.attach(destination:outputLevel:)`.
public protocol SteamcLogDestination: AnyObject {
    /// The minimum level this destination receives. Set by SteamcLog when the destination is attached.
    var outputLevel: LogLevel { get set }
    func write(_ entry: LogEntry)
}

/// Fans log entries out to every destination whose level allows them.
@usableFromInline final class LogDispatcher {
    private(set) var destinations: [SteamcLogDestination] = []

    func add(_ destination: SteamcLogDestination, outputLevel: LogLevel) {
        destination.outputLevel = outputLevel
        destinations.append(destination)
    }

    @usableFromInline func log(_ level: LogLevel, _ message: @autoclosure () -> String, functionName: String, fileName: String, lineNumber: Int, userInfo: [String: Any] = [:]) {
        let enabled = destinations.filter { level.rawValue >= $0.outputLevel.rawValue }
        guard !enabled.isEmpty else { return }
        let entry = LogEntry(level: level, message: message(), functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)
        enabled.forEach { $0.write(entry) }
    }

    /// Housekeeping lines from SteamcLog itself. `source` is skipped, since it's the one reporting.
    func logInternal(_ level: LogLevel, _ message: String, excluding source: SteamcLogDestination? = nil) {
        let entry = LogEntry(level: level, message: message, isInternal: true)
        for destination in destinations where destination !== source && level.rawValue >= destination.outputLevel.rawValue {
            destination.write(entry)
        }
    }
}
