//
//  CustomDestinationViewController.swift
//  SteamcLog_Example
//
//  Created by Brendan on 2020-05-06.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import os
import SteamcLog
import XCGLogger

class CustomLogDestination: BaseQueuedDestination {
    override open func output(logDetails: LogDetails, message: String) {
        if logDetails.level == .error {
            debugPrint("Error: " + message)
        }
    }
}

class CustomDestinationViewController: UIViewController {
    let newClog = SteamcLog( Config(logLevel: .firehose, useCrashlytics: false) )

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create and add a new custom log destination to send logs to
        var customLogDestination = CustomLogDestination()
        newClog.addCustomDestination(destination: &customLogDestination, outputLevel: .error)

        // This message will be picked up by our custom log destination and printed out using `debugPrint`
        newClog.error("I don’t know half of you half as well as I should like and I like less than half of you half as well as you deserve.")
    }
}

