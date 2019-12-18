package com.example.lib

import android.util.Log
import timber.log.Timber

/**
 * PriorityEnabledDebugTree.kt
 *
 * PriorityEnabledTrees are simple extensions of the Timber Tress that allows us to filter
 * logs based on a specific priority level more easily.
 */

/**
 *  Tree -> logging on Release Builds
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

/**
 * Associates a fun emoji with given log levels.
 */
fun PriorityEnabledDebugTree.getLevelEmoji(utilLevel: Int): String? = when(utilLevel) {
    Log.ERROR -> "🚫"
    Log.WARN -> "⚠️"
    else -> null
}