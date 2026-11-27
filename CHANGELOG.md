# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Log calls (except `fatal`) take a `userInfo: [String: any Sendable]`, which reaches destinations on `LogEntry.userInfo`. The console and log file append it to the line, the Sentry destination adds it to breadcrumbs and error extras, and breadcrumbs now include the callsite. Its values follow the same redaction rules as logged objects.
- `error(_:_:)` and `forwardedLog` with an `Error` add it to `userInfo` under `UserInfoKeys.error`, and the Sentry destination reports it with `capture(error:)` instead of a message event. With `requireRedacted` set, only `Redacted` errors are passed along.
- Added `environment` to `SentryConfig`, which sets Sentry's `environment`. It defaults to `debug` or `prod`, replacing the `environment` tag SteamcLog used to set, so saved Sentry searches on that tag should switch to the built-in field.
- Changing `clog.config` while other threads are logging no longer risks a crash. The config is now kept behind a lock, and setting it no longer counts as mutating `clog`, so a `let clog` can change its config too.
- The log file formats each line on the thread that logged it, rather than later on its own queue, so `userInfo` values are described as they were when logged.
- Documented that custom destinations, `suppressError` and `extraInfo` are called from whichever thread logged, and that `SteamcLog` should be created on the main thread so Sentry gets the earliest lines.
- `SteamcLog` is now `Sendable`, so apps in Swift 6 language mode can declare a global `let clog` without `nonisolated(unsafe)`. The package itself now builds in Swift 6 mode (swift-tools 6.0, so Xcode 16 or later). Apps still on Swift 5 mode mostly won't notice, apart from the API changes below. In Swift 6 mode, the compiler now checks what used to be up to you:
  - `SteamcLogDestination` requires `Sendable`. Custom destinations need to be a `final class` with immutable state, or guard their state with a lock or queue and be marked `@unchecked Sendable`.
  - `Config`'s `suppressError` and `extraInfo` closures are `@Sendable`, and `extraInfo` returns `[String: any Sendable]?`.
  - `userInfo` values must be `Sendable`.
  - `Redacted` types need `static let safeProperties`, not `static var`.
- `config` is a `Config` rather than `Config!`, and `sentryConfig` is a `let`. Setting `sentryConfig` after init never did anything.
- `RedactedLogDestination` is a `final class` and takes `safeHeaders` and `safeParams` in its init, rather than as properties set afterwards.
- Add `detach(destination:)` to remove a destination added with `attach(destination:outputLevel:)`.
- Add `attach(destination:)` and `detach(destination:)` for the built-in destinations (`.console`, `.disk`, `.sentry`), so they can be turned off and on at runtime. `SentryConfig(startAttached:)` sets Sentry's starting state.
- Attaching a destination that's already attached does nothing, instead of sending it every line twice.

## [3.0.0]
- Update to use 9.x versions of Sentry SDK. Minimum iOS version is now 15.0, matching Sentry 9.
- Drop CocoaPods support. SteamcLog is now only distributed through Swift Package Manager.
- Replace XCGLogger with os.log. Console output now goes through `Logger` (with real os.log levels, so debug and verbose lines only show up in Console.app when debug messages are enabled), and file logging/rotation is built in. Log files keep the same location, line format, and archive naming.
- Custom destinations now conform to `SteamcLogDestination` (a single `write(_:)` method) instead of subclassing XCGLogger's `BaseQueuedDestination`. `attach(destination:outputLevel:)` takes a `DestinationLevel`: `.console`, `.disk` or `.remote` follow the preset and update when `config` changes, `.fixed(level)` never changes. SteamcLog no longer brings in XCGLogger, so add it directly if your app still uses it.
- The Netable integration (`RedactedLogDestination`) is now the `SteamcLogNetable` SPM product, and supports Netable 2.x.
- Added `allLogFileURLs(includeSystemLog:)`, which returns every log file on disk, and can include a dump of the current launch's os.log entries.
- `fatal` now waits (up to 1 second) for pending log file writes before crashing, so the fatal line is no longer lost from the log file.
- User reports with `detailedLogsOnUserReports` now wait (up to 1 second) for pending log file writes before attaching the log, so the attachment includes the latest lines, including the report itself.
- `userReport(_:_:)` with an object now keeps the message; before, only the object's JSON or redacted description was sent.
- `error` and `userReport` with `requireRedacted` set and a non-`Redacted` object now record the caller's file, function and line instead of SteamcLog's.

## [2.3.2]
- Added a new helper method to forward logs from different sources that are not static.

## [2.3.1]
- Added a new helper method to set a user for tracking and observability purposes.

## [2.3.0]
- Added support to attach previous logs

## [2.2.1]
- Detail log attachment now includes most recent archived log as well as current

## [2.2.0]
- Add flag to attach the detailed logs stored on disk to any 'user report' events
- Add support for adding additional app-specific extra context information to error and user report events.
- Update to use 8.x versions of Sentry SDK

## [2.1.0]
- Add warn/error/fatal entry points that explicitly take an `Error` conforming object as a parameter, for recording more error details
- Add support, when passing in an Error-conforming object, for downgrading errors to warnings based on a user-supplied predicate and the contents of the error instances

## [2.0.0]
- Split Sentry configuration into a separate, optional struct to make not using Sentry a little easier
- Updated LogLevelPreset names and mapped LogLevels (#91)

## [0.5.4]
- Update Sentry code and example app

## [0.5.3]
- Fix Sentry version syntax in the podspec to include all minor versions

## [0.5.2]
- Update Sentry dependency to v7.2.1 

## [0.5.1]
- Add `userReport` to allow sending dynamic user reports to Sentry. (#71)

## [0.4.0]
- Change `fatal` and `error` level log events to accept only `StaticString` messages to prevent duplicate issue creation with Sentry.
- Add optional `info` parameter to log dynamic strings along with `fatal` and `error` logs.

## [0.3.2]
- Add `Codable` conformance to `LogLevelPreset`.

## [0.3.1]
- Update Sentry dependency to v5.1.0.

## [0.3.0]
- Add submodule and `RedactedLogDestination` to play nicely with Netable.
- Add .gitignore file, clean up folder structure.
