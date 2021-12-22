//
//  FilterOut.swift
//  SteamcLog
//
//  Created by Jake Miner on 2021-12-22.
//

import Foundation

/**
 * FilterOut functional interface (ie. should only contain a single method).
 * Allows the application to intercept Errors when an error occurs and decide if the
 * Error should be blocked from being logged as an error by the crash reporting
 * destination.
 */
public protocol FilterOut {
    func shouldBlock(error: Error) -> Bool
}

public class NoFilter: FilterOut {
    public init() { }
    public func shouldBlock(error: Error) -> Bool {
        return false
    }
}
