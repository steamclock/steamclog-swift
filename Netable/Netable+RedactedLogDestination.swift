//
//  Netable+RedactedLogDestination.swift
//  Netable
//
//  Created by Brendan on 2020-05-19.
//

import Foundation

class RedactedLogDestination: LogDestination {
    func log(event: LogEvent) {
        switch event {
        case .requestFailed(let error):
            debugPrint("Request failed: %s", error.localizedDescription)
        default:
            debugPrint("%s", event.debugDescription)
        }
    }
}
