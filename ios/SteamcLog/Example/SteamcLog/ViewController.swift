//
//  ViewController.swift
//  SteamcLog
//
//  Created by blensink192@gmail.com on 01/21/2020.
//  Copyright (c) 2020 blensink192@gmail.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        /// Print a simple message at each output level
        log.verbose("May your beer be laid under an enchantment of surpassing excellence for seven years!")
        log.debug("And some things that should not have been forgotten were lost. History became legend. Legend became myth.")
        log.info("No admittance except on party business.")
        log.warn("All we have to decide is what to do with the time that is given to us.")
        log.error("I don’t know half of you half as well as I should like and I like less than half of you half as well as you deserve.")
        log.fatal("It's the job that's never started as takes longest to finish.")


        let sampleUser = User(name: "Name", uuid: UUID(), email: "hi@steamclock.com", created: Date())
        /// Print a simple model out with some properties redacted
        log.info("Here's a simple model: ", sampleUser)

        /// Log a simple event to Firebase Analytics
        log.track(id: "thing_happened")

        /// Log an event with a RawRepresentable<String> enum
        log.track(id: "card_drawn", value: Suit.heart)

        /// Log an event with a dictionary of values
        log.track(id: "card_drawn", data: ["suit": Suit.heart, "value": "Q"])

        /// Log an event with a redactable object
        log.track(id: "user_created", value : sampleUser)
    }

    @IBAction func showFileContents(_ sender: Any) {
        let alert = UIAlertController(
            title: "Log File Contents",
            message: log.getLogFileContents(),
            preferredStyle: .alert
        )
        alert.addAction( UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

