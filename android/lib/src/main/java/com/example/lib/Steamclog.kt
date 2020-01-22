package com.example.lib

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import com.crashlytics.android.Crashlytics
import io.fabric.sdk.android.Fabric
import org.jetbrains.annotations.NonNls
import timber.log.Timber
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

/**
 * SteamLogger is a wrapper around the Timber logging library, giving us more control over
 * what is logged and when.
 *
 * Priorities using android.util.Log levels:
 * VERBOSE = 2
 * DEBUG = 3
 * INFO = 4
 * WARN = 5
 * ERROR = 6
 * ASSERT = 7
 */
object Steamclog {

    /**
     * Support for NonFatal logging.
     *
     * Android has a `wtf` logging level, but it seems like its purpose to to track issues that should crash the app - as such I do not
     * want to use it to indicate non-fatal. Due to this we do not seem to have access to an "extra" native logging level that we can use for non-fatals.
     * So to support differentiating between a non-fatal and a fatal error (which are both reported on the
     * Log.ERROR level in the console), I am using the NonFatalException to allow our destinations to determine if the error is non fatal or not.
     */
    class NonFatalException(val wrappedThrowable: Throwable? = null): java.lang.Exception()

    //---------------------------------------------
    // Privates
    //---------------------------------------------
    private var crashlyticsTree = CrashlyticsTree()
    private var customDebugTree = CustomDebugTree()
    private var externalLogFileTree = ExternalLogFileTree()

    //---------------------------------------------
    // Public properties
    //---------------------------------------------
    const val defaultPriorityLevel = Log.VERBOSE
    var priorityLevel: Int = defaultPriorityLevel
        set(value) {
            field = value
            crashlyticsTree.priorityLevel = value
            customDebugTree.priorityLevel = value
            externalLogFileTree.priorityLevel = value
        }

    var isCrashlyticsLoggingEnabled: Boolean = false
        private set

    var isCustomLoggingEnabled: Boolean = false
        private set

    var isExternalFileLoggingEnabled: Boolean = false
        private set

    //---------------------------------------------
    // Public methods
    //---------------------------------------------
    fun enableCrashlyticsLogging(enable: Boolean) {
        isCrashlyticsLoggingEnabled = enable
        updateTree(crashlyticsTree, enable)
    }

    fun enableCustomLogging(enable: Boolean) {
        isCustomLoggingEnabled = enable
        updateTree(customDebugTree, enable)
    }

    /**
     * @param enable
     * @param writePath
     */
    @SuppressLint("LogNotTimber")
    fun enableWriteToExternalLogging(enable: Boolean, writePath: File?) {
        isExternalFileLoggingEnabled = enable
        when {
            enable && writePath == null -> {
                Log.e("Steamclog","enableWriteToExternalLogging requires a valid writePath")
                return
            }
            enable -> {
                externalLogFileTree.outputFilePath = writePath
                isExternalFileLoggingEnabled = true
            }
            else -> {
                isExternalFileLoggingEnabled = false
            }
        }

        updateTree(externalLogFileTree, enable)
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

    fun verbose(@NonNls message: String) = Timber.v(message)
    fun verbose(@NonNls message: String, obj: Any) = Timber.v(addObjToMessage(message, obj))

    fun debug(@NonNls message: String) = Timber.d(message)
    fun debug(@NonNls message: String, obj: Any) = Timber.d(addObjToMessage(message, obj))

    fun info(@NonNls message: String) = Timber.i(message)
    fun info(@NonNls message: String, obj: Any) = Timber.i(addObjToMessage(message, obj))

    fun warn(@NonNls message: String) = Timber.w(message)
    fun warn(@NonNls message: String, obj: Any) = Timber.w(addObjToMessage(message, obj))

    fun nonFatal(throwable: Throwable?, @NonNls message: String) = Timber.e(NonFatalException(throwable), message)
    fun nonFatal(throwable: Throwable?, @NonNls message: String, obj: Any) = Timber.e(NonFatalException(throwable), addObjToMessage(message, obj))
    fun nonFatal(@NonNls message: String) = Timber.e(NonFatalException(), message)
    fun nonFatal(@NonNls message: String, obj: Any) = Timber.e(NonFatalException(), addObjToMessage(message, obj))

    fun fatal(@NonNls message: String) = Timber.e(message)
    fun fatal(@NonNls message: String, obj: Any) = Timber.e(addObjToMessage(message, obj))
    fun fatal(throwable: Throwable?, @NonNls message: String) = Timber.e(throwable, message)
    fun fatal(throwable: Throwable?, @NonNls message: String, obj: Any?) = Timber.e(throwable, addObjToMessage(message, obj))

    //---------------------------------------------
    // Public util methods
    //---------------------------------------------
    fun getLogFileContents(): String? {
        if (!isExternalFileLoggingEnabled) return null
        return externalLogFileTree.getLogFileContents()
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

    override fun toString(): String {
        return "Steamclog( \n" +
                    "priorityLevel=$priorityLevel, \n" +
                    "isCrashlyticsLoggingEnabled=$isCrashlyticsLoggingEnabled, \n" +
                    "isCustomLoggingEnabled=$isCustomLoggingEnabled) \n" +
                    "isExternalFileLoggingEnabled=$isExternalFileLoggingEnabled) \n"
    }
}