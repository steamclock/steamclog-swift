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

    public func verbose(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.verbose(logString)
    }

    // MARK: Debug Log Level

    public func debug(_ message: String) {
        xcgLogger.debug(message)
    }

    public func debug(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.debug(logString)
    }

    // MARK: Info Log Level

    public func info(_ message: String) {
        xcgLogger.info(message)
    }

    public func info(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.info(logString)
    }

    // MARK: Warn Log Level

    public func warn(_ message: String) {
        xcgLogger.warning(message)
    }

    public func warn(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.warning(logString)
    }

    // MARK: Nonfatal Log Level

    public func error(_ message: String) {
        xcgLogger.error(message)
    }

    public func error(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.error(logString)
    }

    // MARK: Error Log Level

    public func fatal(_ message: String) {
        xcgLogger.severe(message)
    }

    public func fatal(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.severe(logString)
    }

    // MARK: Analytics Tracking Helpers

    public func track<T: RawRepresentable>(id: String, value: T) where T.RawValue == String {
        track(id: id, data: ["data": value.rawValue])
    }

    func track(id: String, data: [String: Any]?) {
        if config.logLevel == .release {
            Analytics.logEvent(id, parameters: data)
        } else {
            info("Skipped logging analytics event: \(id) ...")
        }
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
