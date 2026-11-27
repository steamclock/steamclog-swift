//
//  SentryLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-05-11.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import Sentry

extension LogLevel {
    var sentryLevel: SentryLevel {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        case .fatal: return .fatal
        case .none: return .none
        }
    }
}

class SentryDestination: SteamcLogDestination {

    func write(_ entry: LogEntry) {
        let attributes = entry.attributes

        if entry.level == .error {
            let extra = (entry.userInfo[UserInfoKeys.extraInfo] as? [String: Any] ?? [:]).merging(attributes) { steamclog, _ in steamclog }
            let urls = (entry.userInfo[UserInfoKeys.detailedLogURLs] as? [URL]) ?? []
            let configure: (Scope) -> Void = { scope in
                scope.setExtras(extra)
                urls.forEach { scope.addAttachment(Attachment(path: $0.path)) }
            }

            // Sentry groups and labels issues by the error's type, so send the error itself when there is one.
            if let error = entry.userInfo[UserInfoKeys.error] as? Error {
                SentrySDK.capture(error: error) { scope in
                    configure(scope)
                    scope.setExtra(value: entry.message, key: "message")
                }
            } else {
                let event = Event(level: entry.level.sentryLevel)
                event.message = SentryMessage(formatted: entry.message)
                SentrySDK.capture(event: event, block: configure)
            }
        }

        let breadcrumb = Breadcrumb(level: entry.level.sentryLevel, category: "steamclog")
        breadcrumb.message = entry.message
        breadcrumb.data = SentryDestination.breadcrumbData(for: entry, attributes: attributes)
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    static func breadcrumbData(for entry: LogEntry, attributes: [String: Any]) -> [String: Any]? {
        var data = attributes
        if !entry.isInternal {
            data["file"] = "\((entry.fileName as NSString).lastPathComponent):\(entry.lineNumber)"
            data["function"] = entry.functionName
        }
        return data.isEmpty ? nil : data
    }
}
