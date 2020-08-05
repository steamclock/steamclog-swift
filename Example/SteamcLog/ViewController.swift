//
//  ViewController.swift
//  SteamcLog Example
//
//  Created by Brendan on 01/21/2020.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import SteamcLog
import UIKit

private enum Event: String, AnalyticsEvent {
    case thingHappened
    case cardDrawn
    case userCreated
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        /// Print a simple message at each output level
        clog.verbose("May your beer be laid under an enchantment of surpassing excellence for seven years!")
        clog.debug("And some things that should not have been forgotten were lost. History became legend. Legend became myth.")
        clog.info("No admittance except on party business.")
        clog.warn("All we have to decide is what to do with the time that is given to us.")
        clog.error("I don’t know half of you half as well as I should like and I like less than half of you half as well as you deserve.")
//        clog.fatal("It's the job that's never started as takes longest to finish.")

        let sampleUser = User(name: "Name", uuid: UUID(), email: "hi@steamclock.com", created: Date())
        /// Print a simple model out with some properties redacted
        clog.info("Here's a simple model: ", sampleUser)

        /// Log a simple event to Firebase Analytics
        clog.track(id: Event.thingHappened)

        /// Log an event with a dictionary of values
        clog.track(id: Event.cardDrawn, data: ["suit": Suit.heart, "value": "Q"])

        /// Log an event with an encodable object
        clog.track(id: Event.userCreated, encodable: sampleUser)
    }

    @IBAction func showFileContents(_ sender: Any) {
        let alert = UIAlertController(
            title: "Log File Contents",
            message: clog.getLogFileContents(),
            preferredStyle: .alert
        )
        alert.addAction( UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

