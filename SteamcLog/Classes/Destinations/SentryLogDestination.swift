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
    var outputLevel: LogLevel = .debug

    func write(_ entry: LogEntry) {
        // Unpleasant hack: log file rotation failure is reported from inside the file destination (so is hard to control),
        // has the full filename in it (so is different every time), and can happen on any call-stack (because it just happens on
        // whatever call happens to rotate the log), so does not get de-duplicate well.
        // Convert to a warning breadcrumb and a fixed string error. Not fully suppressing, for now,
        // because there are probably things we could do (super verbose logging) that would exacerbate this,
        // so we should be watching how frequently it happens, just in case.
        if entry.level == .error && entry.message.contains(FileLogDestination.rotationFailedPrefix) {
            let breadcrumb = Breadcrumb(level: .warning, category: "steamclog")
            breadcrumb.message = entry.message
            SentrySDK.addBreadcrumb(breadcrumb)

            let event = Event(level: entry.level.sentryLevel)
            event.message = SentryMessage(formatted: "Unable to rotate log file")
            SentrySDK.capture(event: event)

            return
        }

        if entry.level == .error {
            let event = Event(level: entry.level.sentryLevel)
            event.message = SentryMessage(formatted: entry.message)
            event.extra = entry.userInfo[UserInfoKeys.extraInfo] as? [String: Any]
            SentrySDK.capture(event: event) { scope in
                let urls = (entry.userInfo[UserInfoKeys.detailedLogURLs] as? [URL]) ?? []
                for url in urls {
                    scope.addAttachment(Attachment(path: url.path))
                }
            }
        }

        let breadcrumb = Breadcrumb(level: entry.level.sentryLevel, category: "steamclog")
        breadcrumb.message = entry.message
        SentrySDK.addBreadcrumb(breadcrumb)
    }
}
