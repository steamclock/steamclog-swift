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
        // Unpleasant hack: log file rotation failure is sent from inside XCGLogger (so is hard to control),
        // has the full filename in it (so is different every time), and can happen on any call-stack (because it just happens on
        // whatever call happens to rotate the log), so does not get de-duplicate well.
        // Convert to a warning breadcumb and a fixed string error. Not fully suppressing, for now,
        // becausue there are problaby things we could do (super verbose logging) that would exacerbate this,
        // so we should be watching how frequently it happens, just in case.
        if (logDetails.level == .error) && message.contains("Unable to rotate file") {
            let breadcrumb = Breadcrumb(level: .warning, category: "steamclog")
            breadcrumb.message = logDetails.message
            SentrySDK.addBreadcrumb(crumb: breadcrumb)

            let event = Event(level: logDetails.level.sentryLevel)
            event.message = "Unable to rotate log file"
            SentrySDK.capture(event: event)

            return
        }

        if logDetails.level == .error {
            let event = Event(level: logDetails.level.sentryLevel)
            event.message = logDetails.message
            SentrySDK.capture(event: event)
        }

        let breadcrumb = Breadcrumb(level: logDetails.level.sentryLevel, category: "steamclog")
        breadcrumb.message = logDetails.message
        SentrySDK.addBreadcrumb(crumb: breadcrumb)
    }
}
