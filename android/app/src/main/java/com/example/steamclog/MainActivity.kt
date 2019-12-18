package com.example.steamclog

import android.os.Bundle
import android.util.Log
import com.google.android.material.snackbar.Snackbar
import androidx.appcompat.app.AppCompatActivity
import com.example.lib.Steamclog

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

        Steamclog.enableCustomLogging(true)

        log_things.setOnClickListener { view ->

            Steamclog.verbose("Verbose message")
            Steamclog.verbose("Verbose message", TestMe())

            Steamclog.debug("Debug message")
            Steamclog.debug("Debug message", TestMe())

            Steamclog.info("Info message")
            Steamclog.info("Info message", TestMe())

            Steamclog.warn("Warn message")
            Steamclog.warn("Warn message", TestMe())

            Steamclog.nonFatal("NonFatal message")
            Steamclog.nonFatal("NonFatal message", TestMe())
            Steamclog.nonFatal(Throwable("OriginalNonFatalThrowable"),"NonFatal message")
            Steamclog.nonFatal(Throwable("OriginalNonFatalThrowable"),"NonFatal message", TestMe())

            Steamclog.fatal("Fatal message")
            Steamclog.fatal("Fatal message", TestMe())
            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message")
            Steamclog.fatal(Throwable("OriginalFatalThrowable"),"Fatal message", TestMe())

        }
    }

}
