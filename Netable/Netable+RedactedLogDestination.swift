//
//  Netable+RedactedLogDestination.swift
//  Netable
//
//  Created by Brendan on 2020-05-19.
//

import Netable

public class RedactedLogDestination: LogDestination {
    public var clog: SteamcLog

    public var safeHeaders = Set<String>()
    public var safeParams = Set<String>()

    public init(clog: SteamcLog) {
        self.clog = clog
    }

    public func log(event: LogEvent) {
        switch event {
        case .message(let message):
            clog.info(message.description)
        case .requestCompleted(let statusCode, _, let finalizedResult):
            if let result = finalizedResult as? Redacted {
                clog.info("Request completed with status code \(statusCode)", result)
            } else {
                clog.info("Request completed with status code \(statusCode). Finalized result redacted.")
            }
        case .requestFailed(let error):
            clog.warn("Request failed with error: \(error.errorDescription ?? "UNKNOWN")")
        case .requestStarted(let urlString, let method, let headers, let params):
            clog.info("Started \(method.rawValue) request...")
            clog.info("    URL: \(urlString)")
            clog.info("    Headers: \(redacted(headers: headers))")
            clog.info("    Params: \(redacted(params: params))")
        case .startupInfo(let baseURL, let logDestination):
            clog.info("Netable started with base url: \(baseURL). Log destination: \(logDestination)")
        }
    }

    private func redacted(headers: [String: Any]) -> String {
        return redacted(input: headers, safe: safeHeaders)
    }

    private func redacted(params: [String: Any]?) -> String {
        return redacted(input: params ?? [:], safe: safeParams)
    }

    private func redacted(input: [String: Any], safe: Set<String>) -> String {
        var output = ""

        var first = true
        for(label, value) in input {
            if first {
                first = false
            } else {
                output += ", "
            }
            output += label
            output += ": "
            output += safe.contains(label) ? "\"\(String(describing: value))\"" : "<redacted>"
        }

        return output
    }
}
