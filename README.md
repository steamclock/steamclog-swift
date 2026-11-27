# SteamcLog
[Technical Documentation](https://coda.io/d/SteamcLog-Public-Documentation_dYDBWMQYscM/SteamcLog-Technical-Documentation_suPjU)
[Android Repo](https://github.com/steamclock/steamclog-android)

- [SteamcLog](#steamclog)
  * [Installation](#installation)
  * [Configuration](#configuration)
    + [logLevel: LogLevelPreset](#loglevel-loglevelpreset)
    + [requireRedacted: Bool](#requireredacted-bool)
    + [autoRotateConfig: AutoRotateConfig](#autorotateconfig-autorotateconfig)
    - [sentryFilter: SentryFilter](#sentryfilter-sentryfilter)
  * [Usage](#usage)
  * [Exporting Logs](#exporting-logs)
    + [Variable Redaction](#variable-redaction)

An open source library that consolidates/formalizes the logging setup and usage across all of Steamclock's projects.

## Installation
SteamcLog is distributed with Swift Package Manager. In Xcode, go to File > Add Package Dependencies and enter:
```
https://github.com/steamclock/steamclog-swift
```

Or add it to your `Package.swift`:
```swift
.package(url: "https://github.com/steamclock/steamclog-swift", from: "3.0.0")
```

Note: If your project is using Sentry, you can remove that dependency, as it'll be imported as a dependency for SteamcLog.

In your AppDelegate (or a logging manager), set-up a global instance of SteamcLog:

```swift
import SteamcLog

// defined globally
#if DEBUG
private let config = Config(logLevel: .debugVerbose) // this will be used in debug builds.
#else
private let config = Config(logLevel: .release) // this will be used for release builds
#endif

let clog = SteamcLog(config, sentryConfig: SentryConfig(key: "<your DSN>"))

class AppDelegate: UIApplicationDelegate {
    // ...
}
```

See configuration documentation for details on `logLevel` [here](#configuration).

`SteamcLog` is `Sendable`, so a global `let clog` works in Swift 6 language mode too, and you can log from any thread. Changing `clog.config` later is safe while other threads are logging. Try to create it on the main thread (Swift globals are created on first use, so logging something early in `application(_:didFinishLaunchingWithOptions:)` does it). Sentry finishes starting on the main thread, so lines logged from another thread before then don't reach Sentry.

Anything SteamcLog calls back into your code from (`suppressError`, `extraInfo`, and custom destinations) runs on whichever thread logged the line, so those need to be `@Sendable` / `Sendable` too.

_Firebase Crashlytics is no longer a supported destination for crash reporting_

## Configuration

SteamcLog has a number of configuration options

#### logLevel: LogLevelPreset
Destination logging levels; it is recommended to use the defaults set by Steamclog instead of initializing these manually. In special cases where more data is desired, update this property. See technical documentation for more details on the available presets.

#### requireRedacted: Bool
Default value is `false`.
Require that all logged objects conform to Redacted or are all redacted by default.
This covers `userInfo` values too: with it set, any value that isn't `Redacted` shows as `<redacted>` in every destination.
`Redacted` only controls an error's `debugDescription`. If an error also conforms to `CustomNSError` or `LocalizedError`, Sentry still sends its `errorUserInfo` and localized description unredacted, so keep anything sensitive out of those.

#### autoRotateConfig: AutoRotateConfig
By default, logs will rotate every 10 minutes, and store 10 archived log files.
`AutoRotateConfig` allows customization for the auto-rotating behaviour. 

`AutoRotateConfig` has the following fields:
**fileRotationTime: TimeInterval**: The number of seconds before the log file is rotated and archived.

Additionally, SteamcLog comes with support to log to Sentry:

### Sentry configuration options

#### key: String
Your Sentry key

#### attachStackTrace: Bool
Default value is `true`.
Toggles Sentry automatically attaching stack traces to error reports.

#### autoSessionTracking: Bool
Default value is `true`.
Toggle's Sentry's auto session tracking. More info [here](https://docs.sentry.io/platforms/cocoa/?platform=swift#release-health).

#### debug: Bool
Default value is `false`.
Sets Sentry to debug mode. More info [here](https://docs.sentry.io/error-reporting/configuration/?platform=swift#debug)

#### tracesSampleRate: NSNumber
Default value is 0.0.
Sets the percentage of the tracing data that is collected by Sentry. Values must be between 0 and 1, and values larger than 1 will be set to 1.
Note that setting this to anything greater than 0 can cause projects to blow past their usage quotas by generating far more events than normal.

#### environment: String
Default value is `debug` in debug builds and `prod` otherwise.
Sets Sentry's `environment`, so you can match it to other services (like Datadog's `env`) and filter by it.

#### filter: SentryFilter
By default, all error objects will be sent to Sentry when submitted via the `error` call. 
This allows you to change this behaviour at the SteamcLog Config-level, by passing in a function that filters errors from being logged.
 
```swift
SentryConfig(
    // other fields
    filter: { error in
        if let error = error as? CustomError {
            return true // CustomError errors will no longer be submitted to Sentry
        }
        return false
    }
)
```

## Usage

From there, you can use `clog` anywhere in your application with the following levels. Note that availability of these logs will depend on your Configuration's `logLevel`.

- `clog.verbose` - Log all of the things! Probably only output to the console by developers, never to devices.
- `clog.debug` - Info that is interesting to developers, any information that may be helpful when debugging. Should be stored to system logs for debug builds but never stored in production.
- `clog.info` - Routine app operations, used to document changes in state within the application. Minimum level of log stored in device logs in production.
- `clog.warn` - Developer concerns or incorrect state etc. Something’s definitely gone wrong, but there’s a path to recover
- `clog.error` - Something has gone wrong, report to a remote service (like Sentry)
- `clog.fatal` - Something has gone wrong and we cannot recover, so force the app to close.

Each of these functions has the following 3 available signatures
`clog.<level>(_ message: String)`
`clog.<level>(_ message: String, object: Encodable)`
`clog.<level>(_ message: String, object: Redacted)`

All but `fatal` also take a `userInfo: [String: any Sendable]`, which is passed through to each destination on `LogEntry.userInfo`. The console and log file add it to the end of the line, and the Sentry destination adds it to breadcrumbs, and to the event's extras for errors:

```swift
clog.info("Opened cart", userInfo: ["itemCount": 3])
// [Info] [main] [CartView.swift:42] load() > Opened cart {itemCount: 3}
```

`userInfo` follows the same redaction rules as logged objects: a `Redacted` value is logged as its `debugDescription`, and with `requireRedacted` set, any other value is logged as `<redacted>`.

When you log an `Error` with `clog.error`, SteamcLog also adds it under `UserInfoKeys.error`, and Sentry reports it with `capture(error:)` so issues are grouped by the error's type. If `requireRedacted` is set, only errors that conform to `Redacted` are passed along.

## Exporting Logs

The log file URL is available via `logFileURL() -> URL`, or you can get the log file contents using `clog.getLogFileContents() -> String?`

To bundle up everything for a user report, `await clog.allLogFileURLs() -> [URL]` returns every log file on disk, oldest first: the archived files, then the current one.

Passing `includeSystemLog: true` also writes out everything the app has sent to os.log since launch and adds that file to the end. This picks up lines from other libraries that log through os.log rather than SteamcLog. iOS only lets an app read os.log entries from its current launch, and reading them can take a few seconds. The work happens on a background queue, so it's safe to await from the main actor.

### Variable Redaction

`Redacted` is a protocol that can be conformed to by a struct or class for marking particular fields as safe for logging. By default, a class/struct conforming to `Redacted` will have all fields marked as redacted, and you can define logging-safe field using the `safeProperties` field.

Example:
```swift
import SteamcLog
struct User: Codable, Redacted {
    static let safeProperties = Set<String>(["name", "email"])
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

## Custom Log Destinations

In addition to the Sentry log destination that comes packaged with SteamcLog, you can create your own log destination and attach it to your SteamcLog instance using `attach`.

A destination is any class conforming to `SteamcLogDestination`. `write` is called on whichever thread logged the line, sometimes from several threads at once, so the protocol requires `Sendable`. A final class with only `let` properties is the easy case. If it needs mutable state, guard it with a lock or serial queue and mark the class `@unchecked Sendable`.

```swift
final class MyDestination: SteamcLogDestination {
    func write(_ entry: LogEntry) {
        print(entry.formattedMessage)
    }
}

// Follows the console level of the current preset, and updates if `clog.config` changes.
clog.attach(destination: MyDestination(), outputLevel: .console)

// Or always receives info and above, whatever the preset.
clog.attach(destination: MyDestination(), outputLevel: .fixed(.info))
```

`.console`, `.disk` and `.remote` follow that level of the current `LogLevelPreset`, the same way SteamcLog's built-in destinations do.

## Using SteamcLog with Netable

If you're also using [Netable](https://github.com/steamclock/netable), you can pipe your logs directly from Netable into SteamcLog.

First, add the `SteamcLogNetable` product from this package to your target, alongside `SteamcLog`, and `import SteamcLogNetable` wherever you create your Netable instance.

Then, when you create your Netable instance, set the log destination to `RedactedLogDestination` and pass in a reference to your Steamclog instance, like so:
```
let netable = Netable(baseURL: URL(string: "https://api.thecatapi.com/v1/")!, logDestination: RedactedLogDestination(clog: clog))
```

Header and param values are logged as `<redacted>` unless you list them as safe:
```
RedactedLogDestination(clog: clog, safeHeaders: ["Content-Type"], safeParams: ["page"])
```
