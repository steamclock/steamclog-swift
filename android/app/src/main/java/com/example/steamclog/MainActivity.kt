package com.example.steamclog

import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.lib.*

import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)
        title = "SteamClog Test"

        // clog setup
        clog.config = Config(logLevel = LogLevelPreset.Develop)
        clog.config.logLevel = LogLevelPreset.customUsingBase(clog.config.logLevel, crashlyticsLevel = LogLevel.None)
        clog.config.fileWritePath = externalCacheDir
        clog.deleteLogFile() // Reset for test

        // UI init
        demo_text.text = clog.toString()
        log_things.setOnClickListener { testAllLoggingLevels() }
        dump_file_button.setOnClickListener { testLogDump() }

        level_selector.onItemSelectedListener = object: AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {}

            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                val newLevel = when (position) {
                    0 -> null
                    1 -> LogLevel.Verbose
                    2 -> LogLevel.Debug
                    3 -> LogLevel.Info
                    4 -> LogLevel.Warn
                    else -> LogLevel.Error
                }

                if (newLevel == null) {
                    Steamclog.config.logLevel = LogLevelPreset.Develop
                } else {
                    // For now just set the file level so we can easily see the impact our change makes.
                    Steamclog.config.logLevel = LogLevelPreset.customUsingBase(Steamclog.config.logLevel, fileLevel = newLevel)
                }
            }
        }
    }

    private fun testAllLoggingLevels() {
        Steamclog.verbose("Verbose message")
        Steamclog.verbose("Verbose message", RedactableParent())

        Steamclog.debug("Debug message")
        Steamclog.debug("Debug message", RedactableParent())

        Steamclog.info("Info message")
        Steamclog.info("Info message", RedactableParent())

        Steamclog.warn("Warn message")
        Steamclog.warn("Warn message", RedactableParent())

        Steamclog.error("Error message")
        Steamclog.error("Error message", RedactableParent())
        Steamclog.error("Error message", Throwable("OriginalNonFatalThrowable"))
        Steamclog.error("Error message", Throwable("OriginalNonFatalThrowable"), RedactableParent())

        // These will crash app
//            Steamclog.fatal("Fatal message")
//            Steamclog.fatal("Fatal message", TestMe())
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message")
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message", TestMe())

        Toast.makeText(applicationContext, "Logged some things! Check your console or show the dump the log.", Toast.LENGTH_LONG).show()
    }

    private fun testLogDump() = GlobalScope.launch(Dispatchers.Main) {
        demo_text?.text = Steamclog.getLogFileContents()
    }


    // Test logging objects
    class RedactableParent : Any(), Redactable {
        val safeProp = "name"
        val secretProp = "WHOOPS"
        val safeRedactedChild = RedactableChild()
        val safeChild = NotRedactedChild()
        val secretChild = NotRedactedChild()

        override val safeProperties: Set<String> = HashSet<String>(setOf("safeProp", "safeRedactedChild", "safeChild"))
    }

    class RedactableChild : Any(), Redactable {
        val safeProp = 22
        val secretProp = "WHOOPS"

        override val safeProperties: Set<String> = HashSet<String>(setOf("safeProp"))
    }

    class NotRedactedChild : Any() {
        val prop1 = "doggo"
        val prop2 = 5
    }

}


