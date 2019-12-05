//
//  SimpleModel.swift
//  SteamcLogExample
//
//  Created by Brendan Lensink on 2019-11-22.
//  Copyright © 2019 steamclock. All rights reserved.
//

import Foundation
import SteamcLog

struct SimpleModel: Codable, Redactable {
    var redactedProperties: [Any] {
        return [uuid, timestamp]
    }

    let name: String
    let uuid: String
    let timestamp: Date
    let amount: Double
}
