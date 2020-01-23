package com.example.lib

import android.os.Build
import com.crashlytics.android.Crashlytics
import timber.log.Timber
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

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

        // If non-fatal, log the original throwable if one was given.
        if (throwable is Steamclog.NonFatalException) {
            Crashlytics.logException(throwable.wrappedThrowable ?: Throwable(message))
        }
    }
}

//---------------------------------------------
// DebugTrees, currently no priority filtering
//---------------------------------------------
/**
 * Reformats console output to include file and line number to log.
 */
open class CustomDebugTree: PriorityEnabledDebugTree() {
    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        val emoji = getLevelEmoji(priority)
        val prettyMessage = if (emoji == null) message else "$emoji $message"
        super.log(priority, createCustomStackElementTag(), prettyMessage, throwable)
    }
}

/**
 *
 */
class ExternalLogFileTree : PriorityEnabledDebugTree() {
    private var fileNamePrefix: String = "SteamLogger"
    private var timestampFormat = "yyyy-MM-dd.HH:mm:ss.SSS"
    private var fileExt = "txt"
    var outputFilePath: File? = null // Must be set with application's external cache dir

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
            Timber.e(tag, "HTMLFileTree failed to write into file: $e")
        }
    }

    private fun getExternalFile(): File? {
        val filename = "$fileNamePrefix.$fileExt" // Todo, per date

        return try {
            File(outputFilePath, filename)
        } catch (e: Exception) {
            Timber.e("HTMLFileTree failed to getExternalFile: $e")
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