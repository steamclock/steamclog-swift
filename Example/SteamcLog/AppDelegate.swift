//
//  AppDelegate.swift
//  SteamcLog Example
//
//  Created by Brendan on 01/21/2020.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import SteamcLog
import UIKit

enum CustomError: Error, Codable {
    case reportedError
    case filteredError
}

var clog = SteamcLog(
    Config(
        sentryKey: "",
        logLevel: .debugVerbose,
        sentryDebug: true,
        sentryFilter: { error in
            if let error = error as? CustomError, error == .filteredError {
                return true
            }
            return false
        }
    )
)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

