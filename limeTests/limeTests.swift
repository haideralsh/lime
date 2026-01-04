//
//  limeTests.swift
//  limeTests
//
//  Created by Haider on 2025-12-31.
//

import Testing
@testable import lime

struct limeTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testMultiWordVariableAssignment() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my age = 20")
        
        #expect(results.count == 1)
        #expect(results[0].error == nil)
        #expect(results[0].value?.asDecimal == 20)
    }
    
    @Test func testMultiWordVariableUsage() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my age = 20\nmy age + 5")
        
        #expect(results.count == 2)
        #expect(results[0].error == nil)
        #expect(results[0].value?.asDecimal == 20)
        #expect(results[1].error == nil)
        #expect(results[1].value?.asDecimal == 25)
    }
    
    @Test func testMultiWordVariableWithThreeWords() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my favorite number = 42\nmy favorite number * 2")
        
        #expect(results.count == 2)
        #expect(results[0].error == nil)
        #expect(results[0].value?.asDecimal == 42)
        #expect(results[1].error == nil)
        #expect(results[1].value?.asDecimal == 84)
    }
    
    @Test func testSingleWordVariableStillWorks() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("x = 10\nx + 5")
        
        #expect(results.count == 2)
        #expect(results[0].error == nil)
        #expect(results[0].value?.asDecimal == 10)
        #expect(results[1].error == nil)
        #expect(results[1].value?.asDecimal == 15)
    }

}
