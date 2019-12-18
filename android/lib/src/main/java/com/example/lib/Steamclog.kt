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

//    enum class Level(val utilLevel: Int) {
//        Verbose(Log.VERBOSE),
//        Debug(Log.DEBUG),
//        Info(Log.INFO),
//        Warn(Log.WARN),
//        NonFatal(Log.ERROR),
//        Fatal(Log.ERROR)
//    }

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
    var priorityLevel: Int = Log.ERROR
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
    // Public Logging calls
    //
    // Problems with wrapping Timber calls:
    // - Timber trace element containing line number and method points to THIS file.
    //---------------------------------------------
    fun verbose(@NonNls message: String, obj: Any? = null) = Timber.v(addObjToMessage(message, obj))
    fun debug(@NonNls message: String, obj: Any? = null) = Timber.d(addObjToMessage(message, obj))
    fun info(@NonNls message: String, obj: Any? = null) = Timber.i(addObjToMessage(message, obj))
    fun warn(@NonNls message: String, obj: Any? = null) = Timber.w(addObjToMessage(message, obj))
    fun nonFatal(throwable: Throwable?, @NonNls message: String, obj: Any? = null) = Timber.e(NonFatalException(throwable), addObjToMessage(message, obj))
    fun nonFatal(@NonNls message: String, obj: Any? = null) = Timber.e(NonFatalException(), addObjToMessage(message, obj))
    fun fatal(@NonNls message: String, obj: Any? = null) = Timber.e(addObjToMessage(message, obj))
    fun fatal(throwable: Throwable?, @NonNls message: String, obj: Any? = null) = Timber.e(throwable, addObjToMessage(message, obj))

    //---------------------------------------------
    // Private methods
    //---------------------------------------------
    private fun addObjToMessage(@NonNls message: String, obj: Any?): String {
        return obj?.let {
            "$message : $it" // Calls obj.toString()
        } ?: run {
            message
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