package com.example.lib

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import com.crashlytics.android.Crashlytics
import io.fabric.sdk.android.Fabric
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

    enum class Level(val utilLevel: Int) {
        Verbose(Log.VERBOSE),
        Debug(Log.DEBUG),
        Info(Log.INFO),
        Warn(Log.WARN),
        NonFatal(Log.ERROR),
        Fatal(Log.ERROR)
    }

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

//---------------------------------------------
// PriorityEnabledTrees, allows us to filter logs based on a specific priority level.
//---------------------------------------------
/**
 *  DebugTree -> logging on Release Builds
 */
abstract class PriorityEnabledTree : Timber.Tree() {
    var priorityLevel: Int = Log.ERROR
    var enabled: Boolean = false
    override fun isLoggable(priority: Int): Boolean { return priority >= priorityLevel }
}

/**
 * DebugTree -> logging on Debug Builds
 */
abstract class PriorityEnabledDebugTree : Timber.DebugTree() {
    var priorityLevel: Int = Log.ERROR
    var enabled: Boolean = false
    override fun isLoggable(priority: Int): Boolean { return priority >= priorityLevel }
}

//---------------------------------------------
// DebugTrees, currently no priority filtering
//---------------------------------------------
/**
 * Uses Crashlytics static methods to log and logException
 */
class CrashlyticsTree : PriorityEnabledTree() {
    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        if (!enabled) return

        // Proxy log to crashlytics
        Crashlytics.log(priority, tag, message)

        // If logging an exception, proxy that to Crashlytics as well
        throwable?.let {
            Crashlytics.logException(it)
        }
    }
}

//---------------------------------------------
// DebugTrees, currently no priority filtering
//---------------------------------------------
/**
 * Reformats console output to include file and line number to log.
 */
class CustomDebugTree: PriorityEnabledDebugTree() {
    override fun createStackElementTag(element: StackTraceElement): String? {
        return "(${element.fileName}:${element.lineNumber}):${element.methodName}"
    }
}

/**
 *
 */
class ExternalLogFileTree : PriorityEnabledDebugTree() {
    var outputFilePath: File? = null
    var fileNamePrefix: String = "SteamLogger"

    //---------------------------------------------
    // Reformats console output to include file and line number to log.
    //---------------------------------------------
    override fun createStackElementTag(element: StackTraceElement): String? {
        return "(${element.fileName}:${element.lineNumber}):${element.methodName}"
    }

    //---------------------------------------------
    // Allows us to print out to an external file if desired.
    //---------------------------------------------
    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        printLogToExternalFile(tag, message)
    }

    //---------------------------------------------
    // Support to write logs out to External HTML file.
    //---------------------------------------------
    private fun printLogToExternalFile(tag: String?, message: String) {
        try {
            val date = Date()
            val fileNameTimeStamp = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault()).format(date)
            val logTimeStamp = SimpleDateFormat("E MMM dd yyyy 'at' hh:mm:ss:SSS aaa", Locale.getDefault()).format(date)

            // Create file
            val file = getExternalFile("$fileNamePrefix-$fileNameTimeStamp.html")

            // If file created or exists save logs
            if (file != null) {
                val writer = FileWriter(file, true)
                writer.apply {
                    append("<p style=\"background:lightgray;\"><strong style=\"background:lightblue;\">&nbsp&nbsp")
                    append(logTimeStamp)
                    append(" :&nbsp&nbsp</strong><strong>&nbsp&nbsp")
                    append(tag)
                    append("</strong> - ")
                    append(message)
                    append("</p>")
                    flush()
                    close()
                }
            }
        } catch (e: Exception) {
            Timber.e(tag, "HTMLFileTree failed to write into file: $e")
        }
    }

    private fun getExternalFile(filename: String): File? {
        return try {
            File(outputFilePath, filename)
        } catch (e: Exception) {
            Timber.e("HTMLFileTree failed to getExternalFile: $e")
            null
        }
    }

    private fun getLogFiles(): List<String> {
        // todo may need to ask for some permissions?
        val filteredFiles = outputFilePath?.list { _, name -> name.contains(fileNamePrefix) }
        return filteredFiles?.sorted() ?: emptyList()
    }

    fun deleteLogFiles() {
        for (file in getLogFiles()) {
            getExternalFile(file)?.delete()
        }
    }
}