package com.example.lib

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
class CustomDebugTree: PriorityEnabledDebugTree() {

    override fun log(priority: Int, tag: String?, message: String, throwable: Throwable?) {
        val emoji = getLevelEmoji(priority)
        val prettyMessage = if (emoji == null) message else "$emoji $message"

        val logThrowable =
            if (throwable is Steamclog.NonFatalException) {
                // If non-fatal, log the original throwable if one was given.
                throwable.wrappedThrowable ?: throwable
            } else {
                throwable
            }

        super.log(priority, createCustomStackElementTag(), prettyMessage, logThrowable)
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