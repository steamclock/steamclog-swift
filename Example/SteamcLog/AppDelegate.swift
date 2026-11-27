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

let clog = SteamcLog(
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

let exampleDestinationEnabledKey = "exampleDestinationEnabled"

/// Stands in for something like a remote logging service, so you can watch it turn on and off in the console.
final class ExampleDestination: SteamcLogDestination {
    func write(_ entry: LogEntry) {
        print("[ExampleDestination] \(entry.formattedMessage)")
    }
}

// Kept around so it can be detached again.
let exampleDestination = ExampleDestination()

func setExampleDestinationAttached(_ attached: Bool) {
    if attached {
        clog.attach(destination: exampleDestination, outputLevel: .fixed(.info))
    } else {
        clog.detach(destination: exampleDestination)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Starts in whatever state the switch in ViewController was last left in.
        setExampleDestinationAttached(UserDefaults.standard.bool(forKey: exampleDestinationEnabledKey))
        return true
    }
}

// The window is created from Main.storyboard via the scene manifest in Info.plist.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
}
