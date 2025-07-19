package com.test.server_simple

import org.springframework.data.jpa.repository.JpaRepository

interface TestRepository: JpaRepository<Test, Long> {

}