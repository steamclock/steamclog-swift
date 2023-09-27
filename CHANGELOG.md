# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
