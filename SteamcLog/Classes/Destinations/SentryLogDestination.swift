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
