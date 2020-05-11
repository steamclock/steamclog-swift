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

class SentryDestination: BaseQueuedDestination {
    override open func output(logDetails: LogDetails, message: String) {
        guard logDetails.level.rawValue >= LogLevel.error.rawValue else { return }

        SentrySDK.capture(message: message)
    }
}
