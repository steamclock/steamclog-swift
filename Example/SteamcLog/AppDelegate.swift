//
//  AppDelegate.swift
//  SteamcLog Example
//
//  Created by Brendan on 01/21/2020.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import SteamcLog
import UIKit

#if DEBUG
var clog = SteamcLog(Config(sentryKey: "", logLevel: .debug, sentryDebug: true))
#else
var clog = SteamcLog(Config(sentryKey: "", logLevel: .develop, sentryDebug: true))
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

