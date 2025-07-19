package com.test.server_simple

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ServerSimpleApplication

fun main(args: Array<String>) {
    runApplication<ServerSimpleApplication>(*args)
}
