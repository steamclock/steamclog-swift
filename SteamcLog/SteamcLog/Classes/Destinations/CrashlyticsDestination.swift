//
//  CrashlyticsDestination.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import FirebaseCrashlytics
import Foundation
import XCGLogger

class CrashlyticsDestination: BaseQueuedDestination {
    override open func output(logDetails: LogDetails, message: String) {
        let args: [CVarArg] = [message]
        withVaList(args) { (argp: CVaListPointer) -> Void in
            Crashlytics.crashlytics().log(format: "%@", arguments: argp)
        }

        if logDetails.level == .error {
            // "code" here is arbitrary, just need it for the NSError constructor. Using a different code than user reports though!
            let error: Error = NSError(domain: "Error Logging: \(logDetails.message)", code: -1002, userInfo: ["reason": "Error Logging: \(logDetails.message)"])
            Crashlytics.crashlytics().record(error: error)
        }
    }
}
