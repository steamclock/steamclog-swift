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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)

        Steamclog.enableCustomLogging(true)

        fab.setOnClickListener { view ->
            Steamclog.verbose("Blah blah is my VERBOSE message")
            Steamclog.debug("What's wrong DEBUG message")
            Steamclog.info("Giving you some INFO")
            Steamclog.warn("WARNING you about a thing")
            Steamclog.nonFatal("Something NONFATAL happened, letstrackit")
            Steamclog.nonFatal(Throwable("Blorpin NonFatal"), "Something NONFATAL happened with a Throwable, letstrackit")
            Steamclog.fatal("Blorpin' FATAL error happened")
        }
    }

}
