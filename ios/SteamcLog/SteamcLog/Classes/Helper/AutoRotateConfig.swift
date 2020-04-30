//
//  AutoRotateConfig.swift
//  SteamcLog
//
//  Created by Jake Miner on 2020-04-29.
//

import Foundation
import XCGLogger

public struct AutoRotateConfig {
    /// The number of seconds before the log file will be rotated out.
    let rotateAfterSeconds: TimeInterval

    public init(rotateAfterSeconds: TimeInterval = AutoRotatingFileDestination.autoRotatingFileDefaultMaxTimeInterval) {
        self.rotateAfterSeconds = rotateAfterSeconds
    }
}
