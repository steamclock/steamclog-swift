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
    fun verbose(@NonNls message: String, vararg args: Any) = Timber.v(message, args)
    fun debug(@NonNls message: String, vararg args: Any) = Timber.d(message, args)
    fun info(@NonNls message: String, vararg args: Any) = Timber.i(message, args)
    fun warn(@NonNls message: String, vararg args: Any) = Timber.w(message, args)
    fun nonFatal(throwable: Throwable?, @NonNls message: String, vararg args: Any) = Timber.e(NonFatalException(throwable), message, args)
    fun nonFatal(@NonNls message: String, vararg args: Any) = Timber.e(NonFatalException(), message, args)
    fun fatal(@NonNls message: String, vararg args: Any) = Timber.e(message, args)

    //---------------------------------------------
    // Private methods
    //---------------------------------------------
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

    fun getLevelEmoji(utilLevel: Int): String? = when(utilLevel) {
        Log.ERROR -> "🚫"
        Log.WARN -> "⚠️"
        else -> null
    }
}

//---------------------------------------------
// PriorityEnabledTrees, allows us to filter logs based on a specific priority level.
//---------------------------------------------
/**
 *  DebugTree -> logging on Release Builds
 */
abstract class PriorityEnabledTree : Timber.Tree() {
    var priorityLevel: Int = Log.VERBOSE
    var enabled: Boolean = false
    override fun isLoggable(priority: Int): Boolean { return priority >= priorityLevel }
}

/**
 * DebugTree -> logging on Debug Builds
 */
abstract class PriorityEnabledDebugTree : Timber.DebugTree() {
    var priorityLevel: Int = Log.VERBOSE
    var enabled: Boolean = false
    override fun isLoggable(priority: Int): Boolean { return priority >= priorityLevel }
}

/**
 * Timber is using a specific call stack index to correctly generate the stack element to be used
 * in the createStackElementTag method, which is included in a final method we have no control over.
 * Because we are wrapping Timber calls in Steamclog,alll of our
 * that stack call index point to our library, instead of the calling method.
 *
 * getStackTraceElement uses a call stack index relative to our library, BUT because we cannot override
 * Timber.getTag, we cannot
 */
fun PriorityEnabledDebugTree.getStackTraceElement(): StackTraceElement {

    val SC_CALL_STACK_INDEX = 8 // Need to go back 8 in the call stack to get to the actual calling method.

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
fun PriorityEnabledDebugTree.createCustomStackElementTag(): String {
    val element = getStackTraceElement()
    return "(${element.fileName}:${element.lineNumber}):${element.methodName}"
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

        val prettyMessage = "${Steamclog.getLevelEmoji(priority) ?: ""} $message"

        val logThrowable =
        if (throwable is Steamclog.NonFatalException) {
            // If non-fatal, log the original throwable if one was given.
            throwable.wrappedThrowable ?: Throwable(message)
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