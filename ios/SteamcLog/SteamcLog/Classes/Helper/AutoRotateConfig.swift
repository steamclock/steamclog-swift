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

    /// More information available in https://github.com/DaveWoodCom/XCGLogger#automatic-log-file-rotation and https://github.com/DaveWoodCom/XCGLogger/blob/master/Sources/XCGLogger/Destinations/AutoRotatingFileDestination.swift
    public init(rotateAfterSeconds: TimeInterval = AutoRotatingFileDestination.autoRotatingFileDefaultMaxTimeInterval) {
        self.rotateAfterSeconds = rotateAfterSeconds
    }
}
