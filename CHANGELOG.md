# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Un-released
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
