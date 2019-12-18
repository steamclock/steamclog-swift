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

        Steamclog.enableCustomLogging(true)

        fab.setOnClickListener { view ->

            Steamclog.verbose("blep", TestMe())

            Steamclog.verbose("Blah blah is my VERBOSE message")
            Steamclog.debug("What's wrong DEBUG message")
            Steamclog.info("Giving you some INFO")
            Steamclog.warn("WARNING you about a thing")
            Steamclog.nonFatal("Something NONFATAL happened with no throwable")
            Steamclog.nonFatal(Throwable("Supa NONFATAL"), "Something NONFATAL happened with a Throwable, letstrackit")
            Steamclog.fatal("Blorpin' FATAL error happened with no throwable")
            Steamclog.fatal(Throwable("ooooooooh FATAL"), "Blorpin' FATAL error happened")
        }
    }

}
