# SteamcLog
[Current Proposal Spec](https://docs.google.com/document/d/1GeFAMBn_ZrIP7qVLzcYlCfqDnPiCrgMa0JdrU8HRx94/edit?usp=sharing)

- [SteamcLog](#steamclog)
  * [Installation](#installation)
  * [Configuration](#configuration)
    + [logLevel: LogLevelPreset](#loglevel-loglevelpreset)
    + [autoRotateConfig: AutoRotateConfig](#autorotateconfig-autorotateconfig)
  * [Usage](#usage)
  * [Exporting Logs](#exporting-logs)
    + [Variable Redaction](#variable-redaction)

An open source library that consolidates/formalizes the logging setup and usage across all of Steamclock's projects.

## Installation
Add the following to your podfile then run `pod install`
```
pod 'SteamcLog', :git => "git@github.com:steamclock/steamclog.git"
```

Note: If your project is using Crashlytics, Fabric, or XCGLogger, you can remove those from the podfile, as they'll be imported as dependencies for SteamcLog.

In your AppDelegate (or a logging manager), set-up a global instance of SteamcLog:

```swift
import SteamcLog

// defined globally
#if DEBUG
private let config = Config(logLevel: .firehose) // this will be used in debug builds.
#else
private let config = Config(logLevel: .release) // this will be used for release builds
#endif

let clog = SteamcLog(config: config)

class AppDelegate: UIApplicationDelegate {
    // ...
}
```

See configuration documentation for details on `logLevel` [here](#configuration).

For Crashlytics support, follow the instructions from [the official Crashlytics docs](https://firebase.google.com/docs/crashlytics/get-started?platform=ios), skipping the podfile changes. 


## Configuration

SteamcLog has a number of configuration options

### logLevel: LogLevelPreset
There are four log level presets available, each of which has different logging outputs.

| LogLevelPreset    | Disk Level | System Level | Remote Level | 
|-------------------|------------|--------------|--------------|
| `firehose`        | verbose    | verbose      | none         |
| `develop`         | none       | debug        | none         |
| `release`         | none       | none         | warn         |
| `releaseAdvanced` | verbose    | none         | warn         |

In most cases, you'll be able to get by using `firehose` or `develop` on debug builds, and `release` or `releaseAdvanced` for production builds. 
Note that if you're using `releaseAdvanced` you must build in a way for the client to email you the disk logs.

### autoRotateConfig: AutoRotateConfig
By default, logs will rotate every 10 minutes, and store 10 archived log files.
`AutoRotateConfig` allows customization for the auto-rotating behaviour. 

`AutoRotateConfig` has the following fields:
**fileRotationTime: TimeInterval**: The number of seconds before the log file is rotated and archived.

## Usage

From there, you can use `clog` anywhere in your application with the following levels. Note that availability of these logs will depend on your Configuration's `logLevel`.

`clog.verbose` - Log all of the things! Probably only output to the console by developers, never to devices.
`clog.debug` - Info that is interesting to developers, any information that may be helpful when debugging. Should be stored to system logs for debug builds but never stored in production.
`clog.info` - Routine app operations, used to document changes in state within the application. Minimum level of log stored in device logs in production.
`clog.warn` - Developer concerns or incorrect state etc. Something’s definitely gone wrong, but there’s a path to recover
`clog.error` - Something has gone wrong, report to a remote service (like Crashlytics)
`clog.fatal` - Something has gone wrong and we cannot recover, so force the app to close.

Each of these functions has the following 3 available signatures
`clog.<level>(_ message: String)`
`clog.<level>(_ message: String, object: Encodable)`
`clog.<level>(_ message: String, object: Redacted)`

## Exporting Logs

The log file URL is available via `logFileURL() -> URL`, or you can get the log file contents using `clog.getLogFileContents() -> String?`

### Variable Redaction

`Redacted` is a protocol that can be conformed to by a struct or class for marking particular fields as safe for logging. By default, a class/struct conforming to `Redacted` will have all fields marked as redacted, and you can define logging-safe field using the `safeProperties` field.

Example:
```swift
import SteamcLog
struct User: Codable, Redacted {
    static var safeProperties = Set<String>(["name", "email"])
    let name: String
    let uuid: UUID
    let email: String
    let created: Date
}
```

In this case, when a `User` object is logged by Steamclog, it will log something like the following:
```
let sampleUser = User(name: "Name", uuid: UUID(), email: "hi@steamclock.com", created: Date())
clog.info("Here's a simple model", sampleUser)
```
And the log will output:

`User(name: "Name", uuid: <redacted>, email: "hi@steamclock.com", created: <redacted>)`
