//
//  SteamcLogConfig.swift
//  SteamcLogExample
//
//  Created by Brendan Lensink on 2019-11-22.
//  Copyright © 2019 steamclock. All rights reserved.
//

import Foundation
import SteamcLog

#if DEBUG
var log = SteamcLog(.verbose)
#else
var log = SteamcLog(.verbose)
#endif


