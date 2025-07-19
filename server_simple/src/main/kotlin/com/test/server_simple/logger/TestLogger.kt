package com.test.server_simple.logger

import com.fasterxml.jackson.annotation.JsonInclude
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.slf4j.LoggerFactory

object TestLogger {
    @JvmStatic private val LOGGER = LoggerFactory.getLogger("TEST_LOGGER")!!
    @JvmStatic private val MAPPER = jacksonObjectMapper().setSerializationInclusion(JsonInclude.Include.NON_NULL)

    fun log(log: Log){
        LOGGER.trace(MAPPER.writeValueAsString(log))
    }
}