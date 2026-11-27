//
//  LogDispatcher.swift
//  SteamcLog
//
//  Copyright (c) 2026 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// Fans log entries out to every destination whose level allows them.
/// Also owns the config and each destination's level, so changing the config updates every destination in one place.
/// Unchecked `Sendable` because the compiler can't see that `lock` guards the mutable state.
@usableFromInline final class LogDispatcher: @unchecked Sendable {
    private struct Attached {
        let destination: SteamcLogDestination
        let rule: DestinationLevel
        var level: LogLevel
        var isEnabled: Bool

        func accepts(_ level: LogLevel) -> Bool {
            isEnabled && level.rawValue >= self.level.rawValue
        }
    }

    // Config can change (and destinations be attached) while other threads are logging, so `attached` and `_config`
    // are only touched under this lock. Destinations and config callbacks are called outside it.
    private let lock = NSLock()
    private var attached: [Attached] = []
    private var _config: Config

    var destinations: [SteamcLogDestination] { snapshot().map(\.destination) }

    init(config: Config) {
        _config = config
    }

    /// Setting this re-resolves every destination's level against the new preset. Fixed levels stay as they are.
    @usableFromInline var config: Config {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _config
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _config = newValue
            for index in attached.indices {
                attached[index].level = attached[index].rule.resolve(newValue.logLevel)
            }
        }
    }

    func add(_ destination: SteamcLogDestination, outputLevel rule: DestinationLevel, isEnabled: Bool = true) {
        lock.lock()
        defer { lock.unlock() }
        guard !attached.contains(where: { $0.destination === destination }) else { return }
        attached.append(Attached(destination: destination, rule: rule, level: rule.resolve(_config.logLevel), isEnabled: isEnabled))
    }

    func remove(_ destination: SteamcLogDestination) {
        lock.lock()
        defer { lock.unlock() }
        attached.removeAll { $0.destination === destination }
    }

    /// Turns every attached destination that `matches` on or off, returning false if none did. Used for the built-in
    /// destinations, which can't be removed and re-added since the file has to stay ahead of Sentry.
    @discardableResult func setEnabled(_ isEnabled: Bool, where matches: (SteamcLogDestination) -> Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var found = false
        for index in attached.indices where matches(attached[index].destination) {
            attached[index].isEnabled = isEnabled
            found = true
        }
        return found
    }

    @usableFromInline func log(_ level: LogLevel, _ message: @autoclosure () -> String, functionName: String, fileName: String, lineNumber: Int, userInfo: [String: any Sendable] = [:]) {
        let enabled = snapshot().filter { $0.accepts(level) }
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
        for item in snapshot() where item.destination !== source && item.accepts(level) {
            item.destination.write(entry)
        }
    }
}
