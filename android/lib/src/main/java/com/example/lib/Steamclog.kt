package com.example.lib

import org.jetbrains.annotations.NonNls
import timber.log.Timber

/**
 * Steamclog
 *
 * Created by shayla on 2020-01-23
 *
 * A wrapper around the Timber logging library, giving us more control over what is logged and when.
 */

/**
 * TODOs
 *
 * - check to see how Logs are adding to crash reports - can we control these separate to the system log. talk to Jake.
 * - get clarification on how we know when to send crash reports? Logging levels no longer captures this.
 * - look into Jake's redaction implementation.
 * - Android Encodable equivalent?
 * - add track for Firebase analytics
 * - jitpack hosting
 * - todo coroutines for getLogFile?
 * - create encodable / redactable interfaces ?
 * - track call
 *
 * // Android - is there a difference between IDE log, and system log? I don't think so, I think
// Android Studio is parsing the system log with a given set of parsing rules based on how Log.T is
// formatting.
 *
 */

/**
 * SteamLogger is a wrapper around the Timber logging library, giving us more control over
 * what is logged and when.
 */
typealias clog = Steamclog
object Steamclog {

    //---------------------------------------------
    // Privates
    //---------------------------------------------
    private var crashlyticsTree = CrashlyticsDestination()
    private var customDebugTree = ConsoleDestination()
    private var externalLogFileTree = ExternalLogFileDestination()

    //---------------------------------------------
    // Public properties
    //---------------------------------------------
    var config: Config = Config()

    init {
        // By default plant all trees; setting their level to LogLevel.None will effectively
        // disable that tree, but we do not uproot it.
        updateTree(customDebugTree, true)
        updateTree(crashlyticsTree, true)
        updateTree(externalLogFileTree, true)
    }

    //---------------------------------------------
    // Public Logging <level> calls
    //
    // Problems with wrapping Timber calls:
    // - Timber trace element containing line number and method points to THIS (Steamclog) file.
    //
    // Note, using default parameter values (obj: Any? = null) appears to introduce one more call in the
    // call stack that messes up how we are generating our PriorityEnabledDebugTree's stack element.
    // To get around this for now we explicit versions of each <level> method below without optional
    // parameters.
    //---------------------------------------------
    fun verbose(@NonNls message: String)            = log(LogLevel.Verbose, message)
    fun verbose(@NonNls message: String, obj: Any)  = log(LogLevel.Verbose, message, obj)

    fun debug(@NonNls message: String)              = log(LogLevel.Debug, message)
    fun debug(@NonNls message: String, obj: Any)    = log(LogLevel.Debug, message, obj)

    fun info(@NonNls message: String)               = log(LogLevel.Info, message)
    fun info(@NonNls message: String, obj: Any)     = log(LogLevel.Info, message, obj)

    fun warn(@NonNls message: String)               = log(LogLevel.Warn, message)
    fun warn(@NonNls message: String, obj: Any)     = log(LogLevel.Warn, message, obj)

    fun error(@NonNls message: String)                                   = log(LogLevel.Error, message)
    fun error(@NonNls message: String, obj: Any)                         = log(LogLevel.Error, message, obj)
    //fun error(@NonNls message: String, throwable: Throwable?)            = log(LogLevel.Error, message, throwable)
    fun error(@NonNls message: String, throwable: Throwable?, obj: Any?) = log(LogLevel.Error, message, throwable, obj)

    fun fatal(@NonNls message: String)                                   = log(LogLevel.Fatal, message)
    fun fatal(@NonNls message: String, obj: Any)                         = log(LogLevel.Fatal, message, obj)
    //fun fatal(@NonNls message: String, throwable: Throwable?)            = log(LogLevel.Fatal, message, throwable)
    fun fatal(@NonNls message: String, throwable: Throwable?, obj: Any?) = log(LogLevel.Fatal, message, throwable, obj)

    // todo Currently obj will be logged via toString. If we want to convert to a json object, we
    // will need to determine what json parser (gson/moshi) to use, or expose an interface that the
    // app can provide to do an object to string conversion.
    //fun <T>verbose(@NonNls message: String, obj: T?) = Timber.v(addObjToMessage(message, obj))

    // Mapping onto the corresponding Timber calls.
    private fun log(logLevel: LogLevel, @NonNls message: String) = Timber.log(logLevel.javaLevel, message)
    private fun log(logLevel: LogLevel, @NonNls message: String, obj: Any?) = Timber.log(logLevel.javaLevel, addObjToMessage(message, obj))
    private fun log(logLevel: LogLevel, @NonNls message: String, throwable: Throwable?) = Timber.log(logLevel.javaLevel, throwable, message)
    private fun log(logLevel: LogLevel, @NonNls message: String, throwable: Throwable?, obj: Any?) = Timber.log(logLevel.javaLevel, throwable, addObjToMessage(message, obj))

    //---------------------------------------------
    // Public util methods
    //---------------------------------------------
    // todo coroutines?
    fun getLogFileContents(): String? {
        return externalLogFileTree.getLogFileContents()
    }

    fun deleteLogFile() {
        return externalLogFileTree.deleteLogFile()
    }

    fun addCustomTree(tree: Timber.Tree) {
        Timber.plant(tree)
    }

    //---------------------------------------------
    // Private methods
    //---------------------------------------------
    private fun addObjToMessage(@NonNls message: String, obj: Any?): String {
        return if (obj == null) {
            message
        } else {
            "$message : $obj"
        }
    }

    /**
     * Plants or uproots a tree accordingly.
     */
    private fun updateTree(tree: Timber.Tree, enabled: Boolean) {
        try {
            if (enabled) {
                Timber.plant(tree)
            } else {
                Timber.uproot(tree)
            }
        } catch(e: Exception) {
            // Tree may not be planted, catch exception.
        }
    }
}