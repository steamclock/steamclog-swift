//
//  Netable+RedactedLogDestination.swift
//  Netable
//
//  Created by Brendan on 2020-05-19.
//

import Netable
import SteamcLog

/// Netable calls this from its own threads, so everything is set once in `init`.
public final class RedactedLogDestination: LogDestination {
    public let clog: SteamcLog

    /// Headers and params whose values are logged as-is. Everything else is logged as `<redacted>`.
    public let safeHeaders: Set<String>
    public let safeParams: Set<String>

    public init(clog: SteamcLog, safeHeaders: Set<String> = [], safeParams: Set<String> = []) {
        self.clog = clog
        self.safeHeaders = safeHeaders
        self.safeParams = safeParams
    }

    public func log(event: LogEvent) {
        switch event {
        case .message(let message):
            clog.info(message.description)
        case .requestCreationFailed(_, let error):
            clog.warn("Creation of request failed with error: \(error.errorDescription ?? "UNKNOWN")")
        case .requestSuccess(_, _, let statusCode, _, let finalizedResult):
            if let result = finalizedResult as? Redacted {
                clog.info("Request completed with status code \(statusCode)", result)
            } else {
                clog.info("Request completed with status code \(statusCode). Finalized result redacted.")
            }
        case .requestFailed(_, _, let error):
            clog.warn("Request failed with error: \(error.errorDescription ?? "UNKNOWN")")
        case .requestRetrying(_, _, let error):
            clog.warn("Request retrying due to error: \(error.errorDescription ?? "UNKNOWN")")
        case .requestStarted(let info):
            clog.info("Started \(info.method.rawValue) request...")
            clog.info("    URL: \(info.urlString)")
            clog.info("    Headers: \(redacted(headers: info.headers))")
        case .requestBody(let body):
            clog.info("    Params: \(redacted(params: body))")
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
