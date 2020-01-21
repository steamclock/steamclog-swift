//
//  SimpleModel.swift
//  SteamcLog_Example
//
//  Created by Brendan Lensink on 2020-01-21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import SteamcLog

struct User: Codable, Redactable {
    var redactedProperties: [Any] {
        return [uuid, email]
    }

    let name: String
    let uuid: UUID
    let email: String
    let created: Date
}
