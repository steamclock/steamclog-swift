//
//  AutoRotateConfig.swift
//  SteamcLog
//
//  Created by Jake Miner on 2020-04-29.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public struct AutoRotateConfig {
    /// The number of seconds before the log file will be rotated out.
    let fileRotationTime: TimeInterval

    /// Log files are also rotated once they pass 1MB, and the 10 most recent archives are kept.
    public init(fileRotationTime: TimeInterval = 600) {
        self.fileRotationTime = fileRotationTime
    }
}
