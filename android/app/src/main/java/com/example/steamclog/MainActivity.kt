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

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)
        title = "SteamClog Test"

        // clog setup
        clog.config = Config(logLevel = LogLevelPreset.Develop)
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
                val logLevelPreset = when (position) {
                    0 -> LogLevelPreset.Firehose
                    1 -> LogLevelPreset.Develop
                    2 -> LogLevelPreset.Release
                    3 -> LogLevelPreset.ReleaseAdvanced
                    else -> LogLevelPreset.Firehose
                }

                SteamcLog.config.logLevel = logLevelPreset
            }
        }
    }

    private fun testAllLoggingLevels() {
        SteamcLog.verbose("Verbose message")
        SteamcLog.verbose("Verbose message", RedactableParent())

        SteamcLog.debug("Debug message")
        SteamcLog.debug("Debug message", RedactableParent())

        SteamcLog.info("Info message")
        SteamcLog.info("Info message", RedactableParent())

        SteamcLog.warn("Warn message")
        SteamcLog.warn("Warn message", RedactableParent())

        SteamcLog.error("Error message")
        SteamcLog.error("Error message", RedactableParent())
        SteamcLog.error("Error message", Throwable("OriginalNonFatalThrowable"))
        SteamcLog.error("Error message", Throwable("OriginalNonFatalThrowable"), RedactableParent())

        // These will crash app
//            Steamclog.fatal("Fatal message")
//            Steamclog.fatal("Fatal message", TestMe())
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message")
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message", TestMe())

        Toast.makeText(applicationContext, "Logged some things! Check your console or show the dump the log.", Toast.LENGTH_LONG).show()
    }

    private fun testLogDump() = GlobalScope.launch(Dispatchers.Main) {
        demo_text?.text = SteamcLog.getLogFileContents()
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


