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
    private let scope = Scope()

    override init(owner: XCGLogger? = nil, identifier: String = "") {
        super.init(owner: owner, identifier: identifier)

        scope.setLevel(.error)
    }

    override open func output(logDetails: LogDetails, message: String) {
        let breadcrumb = Breadcrumb(level: logDetails.level.sentryLevel, category: "steamclog")
        breadcrumb.message = logDetails.message
        SentrySDK.addBreadcrumb(crumb: breadcrumb)

        if logDetails.level.rawValue == LogLevel.error.rawValue {
            SentrySDK.capture(message: logDetails.message, scope: scope)
        }
    }
}
