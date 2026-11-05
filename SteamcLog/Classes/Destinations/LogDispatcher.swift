//
//  LogDispatcher.swift
//  SteamcLog
//
//  Copyright (c) 2026 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// Fans log entries out to every destination whose level allows them.
/// Also owns each destination's level, so changing the preset updates every destination in one place.
@usableFromInline final class LogDispatcher {
    private struct Attached {
        let destination: SteamcLogDestination
        let rule: DestinationLevel
        var level: LogLevel
    }

    // Config can change (and destinations be attached) while other threads are logging, so `attached` and `preset`
    // are only touched under this lock. Destinations are written to outside it.
    private let lock = NSLock()
    private var attached: [Attached] = []
    private var preset: LogLevelPreset

    var destinations: [SteamcLogDestination] { snapshot().map(\.destination) }

    init(preset: LogLevelPreset) {
        self.preset = preset
    }

    func add(_ destination: SteamcLogDestination, outputLevel rule: DestinationLevel) {
        lock.lock()
        defer { lock.unlock() }
        attached.append(Attached(destination: destination, rule: rule, level: rule.resolve(preset)))
    }

    /// Re-resolves every destination's level against a new preset. Fixed levels stay as they are.
    func apply(_ preset: LogLevelPreset) {
        lock.lock()
        defer { lock.unlock() }
        self.preset = preset
        for index in attached.indices {
            attached[index].level = attached[index].rule.resolve(preset)
        }
    }

    @usableFromInline func log(_ level: LogLevel, _ message: @autoclosure () -> String, functionName: String, fileName: String, lineNumber: Int, userInfo: [String: Any] = [:]) {
        let enabled = snapshot().filter { level.rawValue >= $0.level.rawValue }
        guard !enabled.isEmpty else { return }
        let entry = LogEntry(level: level, message: message(), functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)
        enabled.forEach { $0.destination.write(entry) }
    }

    private func snapshot() -> [Attached] {
        lock.lock()
        defer { lock.unlock() }
        return attached
    }

    /// Housekeeping lines from SteamcLog itself. `source` is skipped, since it's the one reporting.
    func logInternal(_ level: LogLevel, _ message: String, excluding source: SteamcLogDestination? = nil) {
        let entry = LogEntry(level: level, message: message, isInternal: true)
        for item in snapshot() where item.destination !== source && level.rawValue >= item.level.rawValue {
            item.destination.write(entry)
        }
    }
}
