//
//  SimpleModel.swift
//  SteamcLogExample
//
//  Created by Brendan Lensink on 2019-11-22.
//  Copyright © 2019 steamclock. All rights reserved.
//

import Foundation

struct SimpleModel: Codable {
    let name: String
    let uuid: String
    let timestamp: Date
    let amount: Double
}
