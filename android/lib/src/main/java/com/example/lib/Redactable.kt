package com.example.lib

import java.lang.StringBuilder
import kotlin.reflect.full.declaredMemberProperties

/**
 * Redactable
 *
 * Created by shayla on 2020-01-23
 */


interface Redactable {
    val safeProperties: Set<String> // Abstract, must be set by implementing class

    fun getDebugDescription(): String {

        val builder = StringBuilder()
        val clazz = this.javaClass.kotlin
        val clazzName = this.javaClass.simpleName
        var hasAdded = false

        builder.append("${clazzName}(")

        clazz.declaredMemberProperties.forEachIndexed { i, property ->
            val propName = property.name

            // Don't log safeProperties
            if (propName == "safeProperties") return@forEachIndexed

            // If name not in safeProperties, redact it!
            val propValue = if (safeProperties.contains(property.name)) { property.get(this) } else "<redacted>"

            // Add comma if we have already added at least one item before.
            val spacer = if (hasAdded) ", " else ""
            hasAdded = true

            builder.append("$spacer$propName: $propValue")
        }

        builder.append(")")
        return builder.toString()
    }
}

class LoginInfoz : Any(), Redactable {
    val name = "cooldude"
    val password = "supersecretpassword"
    val myToken = "supersecrettoken"

    override val safeProperties: Set<String> = HashSet<String>(setOf("name"))
}