package com.example.lib

import android.util.Log
import com.crashlytics.android.Crashlytics
import timber.log.Timber
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

//-----------------------------------------------------------------------------
// Default Destination Trees
//
// Each destination uses a Steamclog.config.destinationLevels setting to determine if
// they are to consume the logged item or not.
//-----------------------------------------------------------------------------
/**
 * CrashlyticsDestination
 */
class CrashlyticsDestination : Timber.Tree() {

    override fun isLoggable(priority: Int): Boolean {
        return isLoggable(Steamclog.config.destinationLevels.crashlytics, priority)
    }

    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        Crashlytics.log(priority, tag, message)
        throwable?.let { Crashlytics.logException(throwable) }
    }
}

/**
 * ConsoleDestination
 * DebugTree gives us access to override createStackElementTag
 */
class ConsoleDestination: Timber.DebugTree() {

    override fun isLoggable(priority: Int): Boolean {
        return isLoggable(Steamclog.config.destinationLevels.console, priority)
    }

    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        val emoji = LogLevel.getLogLevel(priority)?.emoji
        val prettyMessage = if (emoji == null) message else "$emoji $message"
        super.log(priority, createCustomStackElementTag(), prettyMessage, throwable)
    }
}

/**
 * ExternalLogFileDestination
 * DebugTree gives us access to override createStackElementTag
 */
class ExternalLogFileDestination : Timber.DebugTree() {
    private var fileNamePrefix: String = "SteamLogger"
    private var timestampFormat = "yyyy-MM-dd'.'HH:mm:ss.SSS"
    private var fileExt = "txt"

    override fun isLoggable(priority: Int): Boolean {
        return isLoggable(Steamclog.config.destinationLevels.file, priority)
    }

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
        printLogToExternalFile(priority, tag, message)
    }

    //---------------------------------------------
    // Support to write logs out to External HTML file.
    //---------------------------------------------
    private fun printLogToExternalFile(priority: Int, tag: String?, message: String) {
        try {
            val date = Date()
            val logTimeStamp = SimpleDateFormat(timestampFormat, Locale.US).format(date)
            val appId = BuildConfig.LIBRARY_PACKAGE_NAME
            val processId = android.os.Process.myPid()
            val threadName = Thread.currentThread().name

            // Create file
            //val file = getExternalFile("$fileNamePrefix-$fileNameTimeStamp.html")
            val file = getExternalFile()

            // If file created or exists save logs
            if (file != null) {
                val logStr = "$logTimeStamp $appId[$processId:$threadName] [$priority] [$tag] > $message"
                val writer = FileWriter(file, true)

                writer.apply {
                    append(logStr)
                    append("\n\r")
                    flush()
                    close()
                }
            }
        } catch (e: Exception) {
            Log.e(Steamclog.config.identifier, "HTMLFileTree failed to write into file: $e")
        }
    }

    private fun getExternalFile(): File? {
        val filename = "$fileNamePrefix.$fileExt" // Todo, per date
        val outputFilePath = Steamclog.config.fileWritePath

        return try {
            File(outputFilePath, filename)
        } catch (e: Exception) {
            Log.e(Steamclog.config.identifier,"HTMLFileTree failed to getExternalFile: $e")
            null
        }
    }

//    private fun getLogFiles(): List<String> {
//        // todo may need to ask for some permissions?
//        val filteredFiles = outputFilePath?.list { _, name -> name.contains(fileNamePrefix) }
//        return filteredFiles?.sorted() ?: emptyList()
//    }
//
//    fun deleteLogFiles() {
//        for (file in getLogFiles()) {
//            getExternalFile(file)?.delete()
//        }
//    }

    fun getLogFileContents(): String? {
        return getExternalFile()?.readText()
    }

    fun deleteLogFile() {
        getExternalFile()?.delete()
    }
}

//-----------------------------------------------------------------------------
// Extensions / Helpers
//-----------------------------------------------------------------------------
/**
 * Determines if the log (at given android.util.Log priority) should be logged given the
 * current tree logging level.
 */
fun Timber.Tree.isLoggable(treeLevel: LogLevel, logPriority: Int): Boolean {
    return (treeLevel != LogLevel.None) && (logPriority >= treeLevel.javaLevel)
}

/**
 * Timber is using a specific call stack index to correctly generate the stack element to be used
 * in the createStackElementTag method, which is included in a final method we have no control over.
 * Because we are wrapping Timber calls in Steamclog,alll of our
 * that stack call index point to our library, instead of the calling method.
 *
 * getStackTraceElement uses a call stack index relative to our library, BUT because we cannot override
 * Timber.getTag, we cannot get access to the stack trace element during our log step. As such,
 * we need to use this method to allow us to get the correct stack trace element associated with the
 * actual call to our Steamclog.
 */
private fun getStackTraceElement(): StackTraceElement {

    val SC_CALL_STACK_INDEX = 10 // Need to go back X in the call stack to get to the actual calling method.

    // ---- Taken directly from Timber ----
    // DO NOT switch this to Thread.getCurrentThread().getStackTrace(). The test will pass
    // because Robolectric runs them on the JVM but on Android the elements are different.
    val stackTrace = Throwable().stackTrace
    check(stackTrace.size > SC_CALL_STACK_INDEX) { "Synthetic stacktrace didn't have enough elements: are you using proguard?" }
    // ------------------------------------

    return stackTrace[SC_CALL_STACK_INDEX]
}

/**
 * Since Timber's createStackElementTag is made unusable to us since getTag is final, I have created
 * createCustomStackElementTag that makes use of our custom call stack index to give us better filename
 * and linenumber reporting.
 */
private fun createCustomStackElementTag(): String {
    val element = getStackTraceElement()
    return "(${element.fileName}:${element.lineNumber}):${element.methodName}"
}