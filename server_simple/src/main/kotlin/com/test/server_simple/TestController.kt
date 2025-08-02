package com.test.server_simple

import com.test.server_simple.logger.HelloLog
import com.test.server_simple.logger.Log
import com.test.server_simple.logger.LogType
import com.test.server_simple.logger.TestLogger
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/test")
class TestController(
    private val testService: TestService
) {
    @GetMapping("/hello")
    fun hello(): String {
        TestLogger.log(
            Log(
                type = LogType.FIRST,
                HelloLog(
                    id = "1",
                    message = "test test test loki"
                )
            )
        )
        return "Hello, World!"
    }

    @GetMapping("/log")
    fun log() {
        testService.simpleLog()
    }

    @GetMapping("/error")
    fun error() {
        throw RuntimeException("error")
    }

    @GetMapping("/longTime")
    fun longTime(): String {
        Thread.sleep(5000) // Simulate a long-running operation
        TestLogger.log(
            Log(
                type = LogType.FIRST,
                HelloLog(
                    id = "2",
                    message = "long time no see"
                )
            )
        )
        return "Long time operation completed!"
    }
}