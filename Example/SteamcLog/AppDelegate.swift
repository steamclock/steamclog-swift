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
        logLevel: .debugVerbose,
        suppressError: { error in
            if let error = error as? CustomError, error == .filteredError {
                return true
            }
            return false
        }
    ),
    sentryConfig: SentryConfig(key: "", debug: true)
)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

// The window is created from Main.storyboard via the scene manifest in Info.plist.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
}
