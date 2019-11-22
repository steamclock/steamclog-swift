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
        log.verbose("this is verbose")
        log.debug("this is debug")
        log.info("this is info")
        log.warning("this is warn")
        log.error("this is error")
    }
}

