//
//  SteamcLog.swift
//  steamclog
//
//  Created by Brendan on 01/20/2020.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import Sentry

public struct SteamcLog {
    public var config: Config! {
        didSet {
            dispatcher.apply(config.logLevel)
        }
    }

    // Sentry configuration options. If this is not set (or set to nil during creation), Sentry will not be used.
    public var sentryConfig: SentryConfig?

    @usableFromInline internal let dispatcher: LogDispatcher
    @usableFromInline internal let encoder = JSONEncoder()

    /*
     * Create your SteamcLog object.
     * We recommend setting up a global instance of SteamcLog, probably in your AppDelegate file.
     *
     * - Parameters:
     *   - config: General configuration options. See Config.swift for details.
     *   - sentryConfig: Sentry configuration options. If this is `nil`, Sentry will not be used.
     */
    public init(_ config: Config, sentryConfig: SentryConfig?) {
        self.config = config
        self.sentryConfig = sentryConfig
        self.dispatcher = LogDispatcher(preset: config.logLevel)

        // Added before the Sentry destination. Destinations get each entry in the order they were added, so a user
        // report's own line is in the log file by the time Sentry attaches it.
        let file = FileLogDestination(fileURL: logFilePath, maxTimeInterval: config.autoRotateConfig.fileRotationTime)
        dispatcher.add(file, outputLevel: .disk)

        if let sentry = sentryConfig {
            SentrySDK.configureScope { scope in
                #if DEBUG
                scope.setTag(value: "debug", key: "environment")
                #else
                scope.setTag(value: "prod", key: "environment")
                #endif
            }

            SentrySDK.start { options in
                options.dsn = sentry.key
                options.debug = sentry.debug
                options.attachStacktrace = sentry.attachStackTrace
                options.enableAutoSessionTracking = sentry.autoSessionTracking
                options.tracesSampleRate = sentry.tracesSampleRate
            }

            dispatcher.add(SentryDestination(), outputLevel: .remote)
        }

        // Opened after Sentry is set up, so Sentry still gets the "writing log to" breadcrumb.
        file.onInternalLog = { [weak dispatcher, unowned file] level, message in
            dispatcher?.logInternal(level, message, excluding: file)
        }
        file.open()

        dispatcher.add(SteamcLogSystemLogDestination(category: config.identifier), outputLevel: .console)

        // The file destination already wrote these details when it opened.
        dispatcher.logInternal(.info, LogEntry.appDetails, excluding: file)
    }

    @usableFromInline internal func log(_ level: LogLevel, _ message: @autoclosure () -> String, functionName: StaticString, fileName: StaticString, lineNumber: Int, userInfo: [String: Any] = [:]) {
        dispatcher.log(level, message(), functionName: "\(functionName)", fileName: "\(fileName)", lineNumber: lineNumber, userInfo: userInfo)
    }

    private let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

        // Not completely clear what multiple urls in this array mean (something to do with the various "domains" in the mask, I think),
        // why the last one is the one we want to use, why this doesn't use "urls.last!", or if that array could ever be empty.
        // This duplicates the way XCGLogger (our previous logging backend) did it, so the log file stays in the same place.
        return urls[urls.endIndex - 1]
    }()

    // Path for the log file in the cache directory
    private var logFilePath: URL {
        get {
            return cacheDirectory.appendingPathComponent("steamclog.txt")
        }
    }

    // Archived log files in the cache directory, oldest first
    private var archivedLogFilePaths: [URL] {
        let allFiles = (try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path)) ?? []

        // slightly hacky, but we know the archive filenames are constructed such that alphabetical sort does do time sorting
        return allFiles.filter { $0.hasPrefix("steamclog_") }.sorted().map { cacheDirectory.appendingPathComponent($0) }
    }

    // Path for the previous log file in the cache directory
    private var previousLogFilePath: URL? {
        return archivedLogFilePaths.last
    }

    // MARK: - Public Methods

    /*
     * Attach a new custom log destination to the current logger
     *
     * - Parameters:
     *   - destination: The new destination to attach to the logger.
     *   - outputLevel: Which level the destination receives. `.console`, `.disk` or `.remote` follow that level of the
     *     current preset and update whenever `config` changes. `.fixed(level)` always uses `level`.
     */
    public func attach(destination: SteamcLogDestination, outputLevel: DestinationLevel) {
        dispatcher.add(destination, outputLevel: outputLevel)
    }

    // MARK: All Log Level

    private func internalVerbose(_ message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        log(.verbose, message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func verbose(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalVerbose(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func verbose<T>(_ message: String, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                verbose("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            verbose("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                verbose(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
        }

        verbose("\(message): \(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func verbose(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        verbose("\(message): \(object)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Debug Log Level

    private func internalDebug(_ message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        log(.debug, message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func debug(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalDebug(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func debug<T>(_ message: String, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                debug("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            debug("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                debug(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
        }

        debug("\(message): \(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func debug(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        debug("\(message): \(object)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Info Log Level

    private func internalInfo(_ message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        log(.info, message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func info(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalInfo(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func info<T>(_ message: String, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                info("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            info("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                info(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
        }

        info("\(message): \(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func info(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        info("\(message): \(object)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Warn Log Level

    private func internalWarn(_ message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        log(.warn, message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func warn(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalWarn(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func warn<T>(_ message: String, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                warn("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            warn("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                warn(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
        }

        warn("\(message): \(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    @_disfavoredOverload
    public func warn<T>(_ message: String, _ error: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Error {
        if config.requireRedacted {
            guard let redacted = error as? Redacted else {
                warn("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            warn("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        warn("\(message): \(error)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }


    public func warn(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        warn("\(message): \(object)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Non-static NonFatal Log Level

    private func internalUserReport(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        var detailedLogPaths: [URL] = []

        if config.detailedLogsOnUserReports {
            detailedLogPaths = [logFilePath, previousLogFilePath].compactMap { $0 }
        }

        let userInfo: [String: Any] = [
            UserInfoKeys.extraInfo: config.extraInfo(.userReport) as Any,
            UserInfoKeys.detailedLogURLs: detailedLogPaths
        ]

        log(.error, "\(message)", functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)
    }

    public func userReport(_ message: String, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalUserReport(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func userReport<T>(_ message: String, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                internalUserReport("\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            internalUserReport("\(message): \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            internalUserReport(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        internalUserReport("\(message): \(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func userReport(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalUserReport("\(message): \(object.debugDescription)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Nonfatal Log Level

    private func internalError(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        if let info = info {
            log(.info, info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        let userInfo: [String: Any] = [
            UserInfoKeys.extraInfo: config.extraInfo(.error) as Any,
        ]

        log(.error, "\(message)", functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)
    }

    public func error(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalError(message, info: info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func error<T>(_ message: StaticString, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {

        if let error = object as? Error, config.suppressError(error) {
            warn("[suppressed] \(message)", object, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                internalError(message, info: "\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            internalError(message, info: "\(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                internalError(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
        }

        internalError(message, info: jsonString, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    @_disfavoredOverload
    public func error<T>(_ message: StaticString, _ error: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Error {

        if config.suppressError(error) {
            warn("[suppressed] \(message)", error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }


        if config.requireRedacted {
            guard let redacted = error as? Redacted else {
                internalError(message, info: "\(message): Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                return
            }
            internalError(message, info: "\(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }

        internalError(message, info: "\(error)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func error(_ message: StaticString, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalError(message, info: object.debugDescription, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Fatal Log Level

    @_transparent
    public func fatal(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never {
        if let info = info {
            log(.info, info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        let userInfo: [String: Any] = [
            UserInfoKeys.extraInfo: config.extraInfo(.fatal) as Any,
        ]

        log(.fatal, "\(message)", functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo)

        // forcing a crash, so we get a stacktrace
        let cleanfileName = ("\(fileName)" as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        fatalError("\(cleanfileName).\(functionName) - Line \(lineNumber): \(message)")
    }

    @_transparent
    public func fatal<T>(_ message: StaticString, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                fatal(message, info: "Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            }
            fatal(message, info: "\(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        guard let jsonData = try? encoder.encode(object),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                fatal(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        fatal(message, info: "\(jsonString)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    @_transparent
    @_disfavoredOverload
    public func fatal<T>(_ message: StaticString, _ error: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never where T: Error {
        if config.requireRedacted {
            guard let redacted = error as? Redacted else {
                fatal(message, info: "Object redacted due to config.requireRedacted set to true", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            }
            fatal(message, info: "\(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        fatal(message, info: "\(error)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    @_transparent
    public func fatal(_ message: StaticString, _ redacted: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never {
        fatal(message, info: "Object redacted due to config.requireRedacted set to true \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Non-static Helper

    /// Forwards a dynamically constructed (non-static) message from external sources.
    ///
    /// Intended use
    /// - This API exists primarily to forward logs originating from libraries, frameworks, or other logging systems into SteamcLog.
    ///   It helps preserve the original message while routing it through the same destinations (console, file, Sentry) as the rest of your app.
    ///
    /// CAUTION
    /// - Prefer the typed, level-specific APIs (e.g., `debug(_:)`, `info(_:)`, `warn(_:)`, `error(_:info:)`, `fatal(_:)`) that take
    ///   `StaticString` where possible. Those functions help group identical issues together upstream (e.g., in Sentry)
    ///   because the message string is stable.
    /// - Using this forwarding API with a non-static `String` at `.error` (or higher) can produce many distinct log entries in Sentry,
    ///   fragmenting analytics and making it harder to correlate and track the same underlying error.
    /// - Treat this as a last resort for app-generated logs; prefer the other logging functions whenever you can.
    ///
    /// Guidance
    /// - If you must forward dynamic data, keep the `message` as stable as possible and place changing values in `object` so they can be
    ///   serialized or redacted. Alternatively, prefer `error(_:info:)` where the primary message is a `StaticString`.
    ///
    /// Parameters
    /// - level: The log level. Be especially cautious with `.error` and above due to analytics fragmentation.
    /// - message: A non-static `String` from an external source.
    /// - object: Optional associated value to include for additional context (may be serialized or redacted).
    /// - functionName: The calling function from the external or bridging context.
    /// - fileName: The calling file from the external or bridging context.
    /// - lineNumber: The calling line from the external or bridging context.
    public func forwardedLog(level: LogLevel, message: String, object: Any?, functionName: String, fileName: String, lineNumber: Int) {
        dispatcher.log(level, {
            var info: String?

            if let object {
                if config.requireRedacted {
                    if let redacted = object as? Redacted {
                        info = redacted.debugDescription
                    } else {
                        info = "Object redacted due to config.requireRedacted set to true"
                    }
                } else if let error = object as? Error {
                    info = error.localizedDescription
                } else if
                    let encodable = object as? Encodable,
                    let jsonData = try? encoder.encode(encodable),
                    let jsonString = String(data: jsonData, encoding: .utf8)
                {
                    info = jsonString
                } else {
                    info = String(describing: object)
                }
            }

            if let info {
                return "\(message)\n\(info)"
            } else {
                return message
            }
        }(), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: User Related Helpers

    public func setUser(userId: String?) {
        guard let userId = userId else {
            SentrySDK.setUser(nil)
            return
        }
        let sentryUser = User(userId: userId)
        SentrySDK.setUser(sentryUser)
    }

    // MARK: Analytics Tracking Helpers

    @available(*, deprecated, message: "No analytics platform currently supported.")
    public func track<T: RawRepresentable>(id: T, data: [String: Any]? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T.RawValue == String {
        guard config.logLevel.analyticsEnabled else {
            info("Skipped logging analytics event: \(id) ...", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            return
        }
        // TODO: Add an analytics tracking platform to work with sentry.
    }
    
    @available(*, deprecated, message: "No analytics platform currently supported.")
    public func track<T, U>(id: T, encodable: U, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: AnalyticsEvent, U: Encodable {
        guard let data = try? DictionaryEncoder().encode(encodable) else {
            warn("Failed to encode \(encodable) to dictionary.")
            return
        }
        track(id: id, data: data, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Other public helper functions

    public func logFileURL() -> URL {
        return logFilePath
    }

    public func previousLogFileURL() -> URL? {
        return previousLogFilePath
    }

    /*
     * Every log file on disk, oldest first: the archived files, then the current one.
     *
     * - Parameters:
     *   - includeSystemLog: Also writes out everything this process has sent to os.log since launch, and adds that
     *     file to the end. This picks up lines from other libraries that log through os.log rather than SteamcLog.
     *     Reading os.log can take a few seconds. The work happens on a background queue, so this is safe to await
     *     from the main actor.
     */
    public func allLogFileURLs(includeSystemLog: Bool = false, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) async -> [URL] {
        // Dispatched rather than run inline, since the os.log read blocks its thread and shouldn't tie up the caller's
        // actor or one of Swift concurrency's threads.
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: collectLogFileURLs(includeSystemLog: includeSystemLog, functionName: functionName, fileName: fileName, lineNumber: lineNumber))
            }
        }
    }

    private func collectLogFileURLs(includeSystemLog: Bool, functionName: StaticString, fileName: StaticString, lineNumber: Int) -> [URL] {
        // File writes are queued, so wait for any that are still pending.
        dispatcher.destinations.compactMap { $0 as? FileLogDestination }.forEach { $0.flush() }

        var urls = archivedLogFilePaths + [logFilePath]

        if includeSystemLog {
            // Named so it doesn't match the "steamclog_" archive prefix, and doesn't get rotated out with them.
            let systemLogPath = cacheDirectory.appendingPathComponent("steamclog-oslog.txt")
            do {
                try SteamcLogSystemLogDestination.dump(to: systemLogPath)
                urls.append(systemLogPath)
            } catch {
                warn("Failed to export os.log entries: \(error)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            }
        }

        return urls
    }

    public func getLogFileContents(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> String? {
        do {
            let fileData = try Data(contentsOf: logFilePath)
            return String(data: fileData, encoding: .utf8)
        } catch {
            warn("Failed to retrieve log file data: \(error)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
        return nil
    }
}

