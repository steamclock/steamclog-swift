package com.example.lib

/**
 * DestinationLevels
 *
 * Created by shayla on 2020-01-23
 */
sealed class LogLevelPreset {
    data class Custom(val globalLevel: LogLevel, val consoleLevel: LogLevel, val fileLevel: LogLevel, val crashlyticsLevel: LogLevel): LogLevelPreset()

    /// Disk: verbose, system: verbose, remote: none
    object Firehose: LogLevelPreset()

    /// Disk: none, system: debug, remote: none
    object Develop: LogLevelPreset()

    /// Disk: verbose, system: none, remote: warn
    object ReleaseAdvanced: LogLevelPreset()

    /// Disk: none, system: none, remote: warn
    object Release: LogLevelPreset()

    val global: LogLevel
        get() = when(this) {
            is Firehose -> LogLevel.Info
            is Develop -> LogLevel.Info
            is ReleaseAdvanced -> LogLevel.Info
            is Release -> LogLevel.Warn
            is Custom -> this.globalLevel
        }

    val crashlytics: LogLevel
        get() = when(this) {
            is Firehose -> LogLevel.None
            is Develop -> LogLevel.None
            is ReleaseAdvanced -> LogLevel.Warn
            is Release -> LogLevel.Warn
            is Custom -> this.crashlyticsLevel
        }

    val file: LogLevel
        get() = when(this) {
            is Firehose -> LogLevel.Verbose
            is Develop -> LogLevel.None
            is ReleaseAdvanced -> LogLevel.Verbose
            is Release -> LogLevel.None
            is Custom -> this.fileLevel
        }

    val console: LogLevel
        get() = when(this) {
            is Firehose -> LogLevel.Verbose
            is Develop -> LogLevel.Debug
            is ReleaseAdvanced -> LogLevel.None
            is Release -> LogLevel.None
            is Custom -> this.consoleLevel
        }

    override fun toString(): String {
        return "DestinationLevels(global=$global, console=$console, file=$file, crashlytics=$crashlytics)"
    }

    companion object {
        // allows us to create a custom level with single changes
        fun customUsingBase(base: LogLevelPreset,
                   globalLevel: LogLevel? = null,
                   consoleLevel: LogLevel? = null,
                   fileLevel: LogLevel? = null,
                   crashlyticsLevel: LogLevel? = null): LogLevelPreset {
            return LogLevelPreset.Custom(
                globalLevel = globalLevel ?: base.global,
                consoleLevel = consoleLevel ?: base.console,
                fileLevel =  fileLevel ?: base.file,
                crashlyticsLevel = crashlyticsLevel ?: base.crashlytics)
        }
    }
}
