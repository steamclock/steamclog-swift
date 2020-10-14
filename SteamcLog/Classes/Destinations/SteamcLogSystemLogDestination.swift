//
//  SteamcLogSystemLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-21.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation
import XCGLogger

class SteamcLogSystemLogDestination: AppleSystemLogDestination {
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
