package com.test.server_simple

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class TestService(
    private val testRepository: TestRepository
) {
    private val logger = LoggerFactory.getLogger(TestService::class.java)

    fun simpleLog(){
        logger.info("simple log")
        logger.debug("debug log")
        logger.error("error log")
    }
    fun getAll(): List<Test>{
        return testRepository.findAll()
    }

    fun save(test: Test): Test {
        return testRepository.save(test)
    }
}