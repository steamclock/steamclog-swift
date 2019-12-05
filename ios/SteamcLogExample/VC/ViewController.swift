//
//  ViewController.swift
//  SteamcLogExample
//
//  Created by Brendan Lensink on 2019-11-22.
//  Copyright © 2019 steamclock. All rights reserved.
//

import SteamcLog
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        log.verbose("this is verbose", SimpleModel(name: "Namey McNameface", uuid: UUID().uuidString, timestamp: Date(), amount: 1234.56))
        log.debug("this is debug")
        log.info("this is info")
        log.warn("this is warn")
        log.error("this is error")
    }
}

