//
//  AppDelegate.swift
//  SteamcLog
//
//  Created by blensink192@gmail.com on 01/21/2020.
//  Copyright (c) 2020 blensink192@gmail.com. All rights reserved.
//

import SteamcLog
import UIKit

#if DEBUG
var clog = SteamcLog(Config(logLevel: .debug))
#else
var clog = SteamcLog(Config(logLevel: .develop))
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

