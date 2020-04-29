//
//  AutoRotateConfig.swift
//  FirebaseCore
//
//  Created by Jake Miner on 2020-04-29.
//

import Foundation
import XCGLogger

public struct AutoRotateConfig {
    var rotateAfterSeconds: TimeInterval

    public init(rotateAfterSeconds: TimeInterval = AutoRotatingFileDestination.autoRotatingFileDefaultMaxTimeInterval) {
        self.rotateAfterSeconds = rotateAfterSeconds
    }
}
