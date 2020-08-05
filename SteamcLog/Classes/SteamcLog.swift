//
//  SteamcLog.swift
//  steamclog
//
//  Created by Brendan on 01/20/2020.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import Sentry
import XCGLogger

public struct SteamcLog {
    public var config: Config! {
        didSet {
            sentryDestination.outputLevel = config.logLevel.sentry.xcgLevel
            fileDestination.outputLevel = config.logLevel.file.xcgLevel
            systemDestination.outputLevel = config.logLevel.system.xcgLevel
        }
    }

    @usableFromInline internal var xcgLogger: XCGLogger!
    @usableFromInline internal let encoder = JSONEncoder()

    private var fileDestination: FileDestination!
    private var sentryDestination: SentryDestination!
    private var systemDestination: SteamcLogSystemLogDestination!

    public init(_ config: Config) {
        self.config = config
        xcgLogger = XCGLogger(identifier: config.identifier, includeDefaultDestinations: false)

        xcgLogger.setup(
            level: config.logLevel.global.xcgLevel
        )

        // Set up default destinations
        SentrySDK.start(options: [
            "dsn": config.sentryKey,
            "debug": config.sentryDebug,
            "enableAutoSessionTracking": config.sentryAutoSessionTracking
        ])
        sentryDestination = SentryDestination(identifier: "steamclog.sentryDestination")
        setLoggingDetails(destination: &sentryDestination, outputLevel: config.logLevel.sentry)
        xcgLogger.add(destination: sentryDestination)

        fileDestination = AutoRotatingFileDestination(writeToFile: logFilePath,
                                                      identifier: "steamclog.fileDestination",
                                                      shouldAppend: true,
                                                      maxTimeInterval: config.autoRotateConfig.fileRotationTime)
        setLoggingDetails(destination: &fileDestination, outputLevel: config.logLevel.file)
        xcgLogger.add(destination: fileDestination)
        fileDestination.logQueue = XCGLogger.logQueue

        systemDestination = SteamcLogSystemLogDestination(identifier: "steamclog.systemDestination")
        setLoggingDetails(destination: &systemDestination, outputLevel: config.logLevel.system)
        xcgLogger.add(destination: systemDestination)

        xcgLogger.logAppDetails()
    }

    private func setLoggingDetails<T: BaseQueuedDestination>(destination: inout T, outputLevel: LogLevel) {
        destination.outputLevel = outputLevel.xcgLevel
        destination.showLogIdentifier = false
        destination.showFunctionName = true
        destination.showThreadName = true
        destination.showFileName = true
        destination.showLineNumber = true
        destination.showLevel = true
        destination.showDate = true
    }

    // Adapted from XCGLogger demo app here: https://github.com/DaveWoodCom/XCGLogger/blob/master/DemoApps/iOSDemo/iOSDemo/AppDelegate.swift
    // Path for the log file in the cachesDirectory
    private let logFilePath: URL = {
        // get a list of cache directories
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        // grab the last one, then add steamclog.txt to create the path for the log file
        return urls[urls.endIndex - 1].appendingPathComponent("steamclog.txt")
    }()

    // MARK: - Public Methods

    // MARK: All Log Level

    private func internalVerbose(_ message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        xcgLogger.verbose(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
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
        xcgLogger.debug(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
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
        xcgLogger.info(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
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
        xcgLogger.warning(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
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

    public func warn(_ message: String, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        warn("\(message): \(object)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Nonfatal Log Level

    private func internalError(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        if let info = info {
            xcgLogger.info(info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }

        xcgLogger.error(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func error(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalError(message, info: info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func error<T>(_ message: StaticString, _ object: T, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                internalError(message, info: "\(message): Object redacted due to config.requireRedacted set to true")
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

    public func error(_ message: StaticString, _ object: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        internalError(message, info: object.debugDescription, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    // MARK: Fatal Log Level

    @_transparent
    public func fatal(_ message: StaticString, info: String? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never {
        if let info = info {
            xcgLogger.info(info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
        xcgLogger.severe(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)

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
    public func fatal(_ message: StaticString, _ redacted: Redacted, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) -> Never {
        fatal(message, info: "Object redacted due to config.requireRedacted set to true \(redacted)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
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
