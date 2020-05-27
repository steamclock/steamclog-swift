//
//  SentryLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-05-11.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import Sentry
import XCGLogger

extension XCGLogger.Level {
    var sentryLevel: SentryLevel {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .severe: return .fatal
        case .none: return .none
        case .notice, .alert, .emergency: return .none
        }
    }
}

class SentryDestination: BaseQueuedDestination {
    override init(owner: XCGLogger? = nil, identifier: String = "") {
        super.init(owner: owner, identifier: identifier)
    }

    override open func output(logDetails: LogDetails, message: String) {
        if logDetails.level >= .warning {
                 let event = Event(level: logDetails.level.sentryLevel)
                 event.message = logDetails.message
                 SentrySDK.capture(event: event)
        } else {
                 let breadcrumb = Breadcrumb(level: logDetails.level.sentryLevel, category: "steamclog")
                 breadcrumb.message = logDetails.message
                 SentrySDK.addBreadcrumb(crumb: breadcrumb)
        }

    }
}
