//
//  Redactable.swift
//  steamclog
//
//  Created by Brendan Lensink on 2020-01-20.
//

import Foundation

public protocol Redacted: CustomDebugStringConvertible {
    static var safeProperties: Set<String> { get }
    var debugDescription: String { get }
}

public extension Redacted {
    var debugDescription: String {
        var output = ""
        
        // trimmed and modified copy of standard debug print code from https://github.com/apple/swift/blob/master/stdlib/public/core/OutputStream.swift#L284
        let mirror = Mirror(reflecting: self)
        output += String(describing: type(of: self))
        output += "("
        var first = true
        for (label, value) in mirror.children {
          if let label = label {
            if first {
              first = false
            } else {
              output += ", "
            }
            output += label
            output += ": "
            output += Self.safeProperties.contains(label) ? "\"\(String(describing: value))\"" : "<redacted>"
          }
        }
        output += ")"
        return output
    }
}
