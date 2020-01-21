//
//  SteamcLog.swift
//  steamclog
//
//  Created by blensink192@gmail.com on 01/20/2020.
//  Copyright (c) 2020 blensink192@gmail.com. All rights reserved.
//

import Crashlytics
import Fabric
import FirebaseAnalytics
import Foundation
import XCGLogger

public struct SteamcLog {
    public var config: Config!

    private var xcgLogger: XCGLogger!
    private let encoder = JSONEncoder()

    private var crashlyticsDestination: CrashlyticsDestination!
    private var fileDestination: FileDestination!
    private var systemDestination: EnhancedAppleSystemLogDestination!

    public init(_ customConfig: Config = Config()) {
        config = customConfig
        xcgLogger = XCGLogger(identifier: config.identifier, includeDefaultDestinations: config.includeDefaultXCGDestinations)

        xcgLogger.setup(
            level: config.logLevel.global.xcgLevel
        )

        // Set up default destinations
        if config.logLevel == .release {
            crashlyticsDestination = CrashlyticsDestination(identifier: "steamclog.crashlyticsDestination")
            setLoggingDetails(destination: &crashlyticsDestination, outputLevel: config.logLevel.crashlytics)
            Fabric.with([Crashlytics.self])
        }

        fileDestination = FileDestination(writeToFile: logFilePath, identifier: "steamclog.fileDestination", shouldAppend: true)
        setLoggingDetails(destination: &fileDestination, outputLevel: config.logLevel.file)
        xcgLogger.add(destination: fileDestination)
        fileDestination.logQueue = XCGLogger.logQueue

        systemDestination = EnhancedAppleSystemLogDestination(identifier: "steamclog.systemDestination")
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

    public func verbose(_ message: String) {
        xcgLogger.verbose(message)
    }

    public func verbose<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            verbose(message)
            return
        }

        verbose("\(message): \(jsonString)")
    }

    public func verbose(_ message: String, _ object: Redactable) {
        verbose("\(message): \(object.secureToString())")
    }

    // MARK: Debug Log Level

    public func debug(_ message: String) {
        xcgLogger.debug(message)
    }

    public func debug<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            debug(message)
            return
        }

        debug("\(message): \(jsonString)")
    }

    public func debug(_ message: String, _ object: Redactable) {
        debug("\(message): \(object.secureToString())")
    }

    // MARK: Info Log Level

    public func info(_ message: String) {
        xcgLogger.info(message)
    }

    public func info<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            info(message)
            return
        }

        info("\(message): \(jsonString)")
    }

    public func info(_ message: String, _ object: Redactable) {
        info("\(message): \(object.secureToString())")
    }

    // MARK: Warn Log Level

    public func warn(_ message: String) {
        xcgLogger.warning(message)
    }

    public func warn<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            warn(message)
            return
        }

        warn("\(message): \(jsonString)")
    }

    public func warn(_ message: String, _ object: Redactable) {
        warn("\(message): \(object.secureToString())")
    }

    // MARK: Nonfatal Log Level

    public func error(_ message: String) {
        xcgLogger.error(message)
    }

    public func error<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            error(message)
            return
        }

        error("\(message): \(jsonString)")
    }

    public func error(_ message: String, _ object: Redactable) {
        error("\(message): \(object.secureToString())")
    }

    // MARK: Error Log Level

    public func fatal(_ message: String) {
        xcgLogger.severe(message)

        if config.logLevel == .release {
            fatalError()
        }
    }

    public func fatal<T>(_ message: String, _ object: T) where T: Encodable {
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            fatal(message)
            return
        }

        fatal("\(message): \(jsonString)")
    }

    public func fatal(_ message: String, _ object: Redactable) {
        fatal("\(message): \(object.secureToString())")
    }

    // MARK: Analytics Tracking Helpers

    public func track(id: String, data: [String: Any]? = nil) {
        if config.logLevel == .release {
            Analytics.logEvent(id, parameters: data)
        } else {
            info("Skipped logging analytics event: \(id) ...")
        }
    }

    public func track<T: RawRepresentable>(id: String, value: T) where T.RawValue == String {
        track(id: id, data: ["value": value.rawValue])
    }

    public func track(id: String, value: Redactable) {
        track(id: id, data: ["value": value.secureToString()])
    }

    // MARK: Other public helper functions

    public func getLogFileContents() -> String? {
        do {
            let fileData = try Data(contentsOf: logFilePath)
            return String(data: fileData, encoding: .utf8)
        } catch {
            warn("Failed to retrieve log file data: \(error)")
        }
        return nil
    }
}

class EnhancedAppleSystemLogDestination: AppleSystemLogDestination {
    override func output(logDetails: LogDetails, message: String) {
        let emoji: String

        switch logDetails.level {
        case .error, .severe:
            emoji = "🚫"
        case .warning:
            emoji = "⚠️"
        default:
            emoji = ""
        }

        super.output(logDetails: logDetails, message: emoji.isEmpty ? message : "\(emoji) \(message)")
    }
}
