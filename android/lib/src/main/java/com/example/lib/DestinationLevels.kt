package com.example.lib

sealed class DestinationLevels(var console: LogLevel, var file: LogLevel, var crashlytics: LogLevel) {
    class Custom(console: LogLevel, file: LogLevel, crashlytics: LogLevel): DestinationLevels(console, file, crashlytics)

    object Develop: DestinationLevels(console = LogLevel.None, file = LogLevel.None, crashlytics = LogLevel.None)
    object Debug: DestinationLevels(console = LogLevel.Verbose, file = LogLevel.None, crashlytics = LogLevel.None)
    object Test: DestinationLevels(console = LogLevel.None, file = LogLevel.None, crashlytics = LogLevel.None)
    object Release: DestinationLevels(console = LogLevel.None, file = LogLevel.None, crashlytics = LogLevel.None)
    object Restrict3rdParty: DestinationLevels(console = LogLevel.None, file = LogLevel.None, crashlytics = LogLevel.None)
}
