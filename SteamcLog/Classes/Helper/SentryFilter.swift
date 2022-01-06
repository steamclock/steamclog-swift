//
//  SentryFilter.swift
//  SteamcLog
//
//  Created by Jake Miner on 2021-12-22.
//

import Foundation

/**
 * SentryFilter lambda.
 * Allows the application to intercept Errors when an error occurs and decide if the
 * Error should be blocked from being logged as an error by the crash reporting
 * destination.
 */
public typealias SentryFilter = (Error) -> Bool
