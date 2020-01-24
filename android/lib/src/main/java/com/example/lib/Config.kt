package com.example.lib

import java.io.File

/**
 * Config
 *
 * Created by shayla on 2020-01-23
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