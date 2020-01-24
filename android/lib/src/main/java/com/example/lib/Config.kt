package com.example.lib

import java.io.File

/**
 *
 */
data class Config(
    /**
     *
     */
    var destinationLevels: DestinationLevels = DestinationLevels.Debug,
    /**
     *
     */
    var identifier: String = "steamclog",
    /**
     *
     */
    var crashlyticsAppKey: String? = null,
    /**
     *
     */
    var fileWritePath: File? = null)