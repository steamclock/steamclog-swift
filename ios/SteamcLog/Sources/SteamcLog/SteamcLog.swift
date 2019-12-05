//
//  SteamcLog.swift
//  SteamcLog
//
//  Created by Brendan Lensink on 2019-11-15.
//  Copyright © 2019 steamclock. All rights reserved.
//

import Foundation
import XCGLogger

public struct SCLog {
    public var config: SCLogConfig!

    private var xcgLogger: XCGLogger!
    private var systemDestination: EnhancedAppleSystemLogDestination!
    private var fileDestination: FileDestination!

    public init(_ customConfig: SCLogConfig? = nil) {
        config = customConfig ?? SCLogConfig()
        xcgLogger = XCGLogger(identifier: config.identifier, includeDefaultDestinations: config.includeDefaultXCGDestinations)

        xcgLogger.setup(
            level: config.threshold.xcgLevel
        )

        // Set up default destinations
        systemDestination = EnhancedAppleSystemLogDestination(identifier: "steamclog.systemDestination")
        setLoggingDetails(destination: &systemDestination, outputLevel: config.threshold)
        xcgLogger.add(destination: systemDestination)

        fileDestination = FileDestination(writeToFile: logFilePath, identifier: "steamclog.fileDestination", shouldAppend: true)
        setLoggingDetails(destination: &fileDestination, outputLevel: config.threshold)
        xcgLogger.add(destination: fileDestination)
        fileDestination.logQueue = XCGLogger.logQueue

        xcgLogger.logAppDetails()
    }

     private func setLoggingDetails<T: BaseQueuedDestination>(destination: inout T, outputLevel: SCLogLevel) {
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

    public func nonfatal(_ message: String) {
        xcgLogger.error(message)
    }

    public func nonfatal(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.error(logString)
    }


    // MARK: Error Log Level

    public func error(_ message: String) {
        xcgLogger.severe(message)
    }

    public func error(_ message: String?, _ object: Redactable) {
        let logString = (message ?? "") + ": " + object.secureToString()
        xcgLogger.severe(logString)
    }
}

class EnhancedAppleSystemLogDestination: AppleSystemLogDestination {
    override func output(logDetails: LogDetails, message: String) {
        let emoji: String

        switch logDetails.level {
        case .error:
            emoji = "🚫"
        case .warning:
            emoji = "⚠️"
        default:
            emoji = ""
        }

        super.output(logDetails: logDetails, message: emoji.isEmpty ? message : "\(emoji) \(message)")
    }
}
