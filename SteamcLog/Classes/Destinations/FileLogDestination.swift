//
//  FileLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-21.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import XCGLogger

private class FileSystemFormatter: LogFormatterProtocol {
    private let formatter: DateFormatter!

    public init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd.H:m:ss.SSSS"
    }

    func format(logDetails: inout LogDetails, message: inout String) -> String {
        /// Format: Datetime AppID[ProcessID: ThreadName] [LogLevel] (FileName.ext:Line): FunctionName() > Message, JSON: []
        let date = formatter.string(from: logDetails.date)
        let appId = Bundle.main.bundleIdentifier?.split(separator: ".").last ?? "UNKNOWN_BUNDLE"
        let pid = ProcessInfo.processInfo.processIdentifier
        let threadName = Thread.current.isMainThread ? "main" : (Thread.current.name ?? "UNKNOWN_THREAD")
        let filename = logDetails.fileName.split(separator: "/").last ?? "UNKNOWN_FILENAME"

        return "\(date) \(appId)[\(pid):\(threadName)] [\(logDetails.level)] (\(filename):\(logDetails.lineNumber)): \(logDetails.functionName) > \(logDetails.message)"
    }

    var debugDescription: String { return "" } // TODO: what is this?
}

class FileLogDestination: FileDestination {
    override init(owner: XCGLogger? = nil, writeToFile: Any, identifier: String = "", shouldAppend: Bool = false, appendMarker: String? = "-- ** ** ** --", attributes: [FileAttributeKey : Any]? = nil) {
        super.init(owner: owner, writeToFile: writeToFile, identifier: identifier, shouldAppend: shouldAppend, appendMarker: appendMarker, attributes: attributes)
        formatters = [FileSystemFormatter()]
    }

    override func output(logDetails: LogDetails, message: String) {
        var logDetails = logDetails
        var message = message

        let formatter = FileSystemFormatter()
        write(message: formatter.format(logDetails: &logDetails, message: &message))
    }
}
