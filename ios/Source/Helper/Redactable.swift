//
//  Redactable.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public protocol Redactable {
    var redactedProperties: [Any] { get }
}

extension Redactable {
    func secureToString() -> String {
        return redact(insecureString: String(describing: self))
    }

    private func redact(insecureString: String) -> String {
        var returnString = insecureString
        for property in redactedProperties {
            returnString = returnString.replacingOccurrences(of: String(describing: property), with: "<redacted>")
        }

        return returnString
    }
}
