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

        // Turns ExampleDestination on and off. With it off, its "[ExampleDestination]" lines stop showing in the console.
        let example = switchRow("ExampleDestination", isOn: UserDefaults.standard.bool(forKey: exampleDestinationEnabledKey)) { isOn in
            UserDefaults.standard.set(isOn, forKey: exampleDestinationEnabledKey)
            setExampleDestinationAttached(isOn)
        }

        // The built-in destinations use the same attach/detach calls. They always start attached, so these aren't saved.
        let builtIns = [("Console", BuiltInDestination.console), ("Disk", .disk), ("Sentry", .sentry)].map { name, destination in
            switchRow(name, isOn: true) { isOn in
                if isOn {
                    clog.attach(destination: destination)
                } else {
                    clog.detach(destination: destination)
                }
            }
        }

        let rows = UIStackView(arrangedSubviews: [example] + builtIns)
        rows.axis = .vertical
        rows.alignment = .trailing
        rows.spacing = 8
        rows.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rows.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func switchRow(_ name: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let label = UILabel()
        label.text = name
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.addAction(UIAction { [unowned toggle] _ in
            onChange(toggle.isOn)
            // Logged after the change, so this line only shows up in destinations that are still on.
            clog.info("\(name) turned \(toggle.isOn ? "on" : "off")")
        }, for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [label, toggle])
        row.spacing = 8
        return row
    }

    @IBAction func runTests() {
        clog.verbose("May your beer be laid under an enchantment of surpassing excellence for seven years!")
        clog.debug("And some things that should not have been forgotten were lost. History became legend. Legend became myth.")
        clog.info("No admittance except on party business.")
        clog.warn("All we have to decide is what to do with the time that is given to us.")
        clog.error("I don’t know half of you half as well as I should like and I like less than half of you half as well as you deserve.")

        clog.error("Reported error", CustomError.reportedError)
        clog.error("Filtered error", CustomError.filteredError)

        // Uncomment to test fatal errors.
        // clog.fatal("It's the job that's never started as takes longest to finish.")

        /*
         * Uncomment to test analytics.
         *
        let sampleUser = User(name: "Name", uuid: UUID(), email: "hi@steamclock.com", created: Date())
        /// Print a simple model out with some properties redacted
        clog.info("Here's a simple model: ", sampleUser)

        /// Log a simple event to Firebase Analytics
        clog.track(id: Event.thingHappened)

        /// Log an event with a dictionary of values
        clog.track(id: Event.cardDrawn, data: ["suit": Suit.heart, "value": "Q"])

        /// Log an event with an encodable object
        clog.track(id: Event.userCreated, encodable: sampleUser)
         *
         */
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

