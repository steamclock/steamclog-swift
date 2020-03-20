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
    public var config: Config! {
        didSet {
            crashlyticsDestination.outputLevel = config.logLevel.crashlytics.xcgLevel
            fileDestination.outputLevel = config.logLevel.file.xcgLevel
            systemDestination.outputLevel = config.logLevel.system.xcgLevel
        }
    }

    private var xcgLogger: XCGLogger!
    private let encoder = JSONEncoder()

    private var crashlyticsDestination: CrashlyticsDestination!
    private var fileDestination: FileDestination!
    private var systemDestination: SteamcLogSystemLogDestination!

    public init(_ customConfig: Config = Config()) {
        config = customConfig
        xcgLogger = XCGLogger(identifier: config.identifier, includeDefaultDestinations: config.includeDefaultXCGDestinations)

        xcgLogger.setup(
            level: config.logLevel.global.xcgLevel
        )

        // Set up default destinations
        crashlyticsDestination = CrashlyticsDestination(identifier: "steamclog.crashlyticsDestination")
        setLoggingDetails(destination: &crashlyticsDestination, outputLevel: config.logLevel.crashlytics)
        Fabric.with([Crashlytics.self])

        fileDestination = FileLogDestination(writeToFile: logFilePath, identifier: "steamclog.fileDestination", shouldAppend: true)
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

    public func verbose(_ message: String) {
        xcgLogger.verbose(message)
    }

    public func verbose<T>(_ message: String, _ object: T) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                verbose("\(message): Object redacted due to config.requireRedacted set to true")
                return
            }
            verbose("\(message): \(redacted)")
            return
        }
        
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            verbose(message)
            return
        }

        verbose("\(message): \(jsonString)")
    }

    public func verbose(_ message: String, _ object: Redacted) {
        verbose("\(message): \(object)")
    }

    // MARK: Debug Log Level

    public func debug(_ message: String) {
        xcgLogger.debug(message)
    }

    public func debug<T>(_ message: String, _ object: T) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                debug("\(message): Object redacted due to config.requireRedacted set to true")
                return
            }
            debug("\(message): \(redacted)")
            return
        }
        
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            debug(message)
            return
        }

        debug("\(message): \(jsonString)")
    }

    public func debug(_ message: String, _ object: Redacted) {
        debug("\(message): \(object)")
    }

    // MARK: Info Log Level

    public func info(_ message: String) {
        xcgLogger.info(message)
    }

    public func info<T>(_ message: String, _ object: T) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                info("\(message): Object redacted due to config.requireRedacted set to true")
                return
            }
            info("\(message): \(redacted)")
            return
        }
        
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            info(message)
            return
        }

        info("\(message): \(jsonString)")
    }

    public func info(_ message: String, _ object: Redacted) {
        info("\(message): \(object)")
    }

    // MARK: Warn Log Level

    public func warn(_ message: String) {
        xcgLogger.warning(message)
    }

    public func warn<T>(_ message: String, _ object: T) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                warn("\(message): Object redacted due to config.requireRedacted set to true")
                return
            }
            warn("\(message): \(redacted)")
            return
        }
        
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            warn(message)
            return
        }

        warn("\(message): \(jsonString)")
    }

    public func warn(_ message: String, _ object: Redacted) {
        warn("\(message): \(object)")
    }

    // MARK: Nonfatal Log Level

    public func error(_ message: String) {
        xcgLogger.error(message)
    }

    public func error<T>(_ message: String, _ object: T) where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                error("\(message): Object redacted due to config.requireRedacted set to true")
                return
            }
            error("\(message): \(redacted)")
            return
        }
        
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            error(message)
            return
        }

        error("\(message): \(jsonString)")
    }

    public func error(_ message: String, _ object: Redacted) {
        error("\(message): \(object)")
    }

    // MARK: Error Log Level

    public func fatal(_ message: String) -> Never {
        xcgLogger.severe(message)

        fatalError()
    }

    public func fatal<T>(_ message: String, _ object: T) -> Never where T: Encodable {
        if config.requireRedacted {
            guard let redacted = object as? Redacted else {
                fatal("\(message): Object redacted due to config.requireRedacted set to true")
            }
            fatal("\(message): \(redacted)")
        }
    
        guard let jsonData = try? encoder.encode(object),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
            fatal(message)
        }

        fatal("\(message): \(jsonString)")
    }

    public func fatal(_ message: String, _ redacted: Redacted) -> Never {
        fatal("\(message): \(redacted)")
    }

    // MARK: Analytics Tracking Helpers

    public func track<T: RawRepresentable>(id: T, data: [String: Any]? = nil) where T.RawValue == String {
        if config.logLevel == .release {
            Analytics.logEvent(id.rawValue, parameters: data)
        } else {
            info("Skipped logging analytics event: \(id) ...")
        }
    }

    public func track<T, U>(id: T, encodable: U) where T: AnalyticsEvent, U: Encodable {
        guard let data = try? DictionaryEncoder().encode(encodable) else {
            warn("Failed to encode \(encodable) to dictionary.")
            return
        }
        track(id: id, data: data)
    }

    // MARK: Other public helper functions
    
    public func logFileURL() -> URL {
        return logFilePath
    }

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
