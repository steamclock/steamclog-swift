//
//  AnalyticsEvent.swift
//  SteamcLog
//
//  Created by Brendan on 2020-02-04.
//

import Foundation

public protocol AnalyticsEvent: RawRepresentable where RawValue == String {}
