//
//  AnalyticsEvent.swift
//  SteamcLog
//
//  Created by Brendan on 2020-02-04.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

public protocol AnalyticsEvent: RawRepresentable where RawValue == String {}
