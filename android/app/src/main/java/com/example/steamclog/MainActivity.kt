package com.example.steamclog

import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.AdapterView
import com.google.android.material.snackbar.Snackbar
import androidx.appcompat.app.AppCompatActivity
import com.example.lib.*

import kotlinx.android.synthetic.main.activity_main.*
import java.lang.Exception
import java.util.logging.Level

class MainActivity : AppCompatActivity() {

    class TestMe {
        val one = 1
        val two = 2
        val three = 3
        override fun toString(): String {
            return "TestMe(one=$one, two=$two, three=$three)"
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)
        title = "SteamClog Test"

        clog.config.destinationLevels.crashlytics = LogLevel.None
        clog.config.fileWritePath = externalCacheDir

        clog.deleteLogFile() // Reset for test

        demo_text.text = Steamclog.toString()


       level_selector.onItemSelectedListener = object: AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {

            }

            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                Steamclog.config.destinationLevels.file = when (position) {
                    0 -> LogLevel.Verbose
                    1 -> LogLevel.Debug
                    2 -> LogLevel.Info
                    3 -> LogLevel.Warn
                    else -> LogLevel.Error
                }
            }

        }

        log_things.setOnClickListener { view ->

            Steamclog.verbose("Verbose message")
            Steamclog.verbose("Verbose message", TestMe())

            Steamclog.debug("Debug message")
            Steamclog.debug("Debug message", TestMe())

            Steamclog.info("Info message")
            Steamclog.info("Info message", TestMe())

            Steamclog.warn("Warn message")
            Steamclog.warn("Warn message", TestMe())

            Steamclog.error("Error message")
            Steamclog.error("NonFErroratal message", TestMe())
            //Steamclog.error("NonFatal message", Throwable("OriginalNonFatalThrowable"))
            Steamclog.error("Error message", Throwable("OriginalNonFatalThrowable"), TestMe())

            // These will crash app
//            Steamclog.fatal("Fatal message")
//            Steamclog.fatal("Fatal message", TestMe())
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message")
//            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message", TestMe())

        }

        dump_file_button.setOnClickListener { Steamclog.getLogFileContents()?.let { demo_text.text = it } }

        var num = 1
        var me = "sfdsfsdf$num"

    }
}


