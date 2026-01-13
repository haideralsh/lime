//
//  ExpressionEngineVariableTests.swift
//  limeTests
//

import Testing
import Foundation
@testable import lime

struct ExpressionEngineVariableTests {

    @Test func multiWordVariableAssignment() async throws {
        let results = evaluate("my age = 20")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 20)
    }
    
    @Test func multiWordVariableUsage() async throws {
        let results = evaluate("my age = 20\nmy age + 5")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 20)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 25)
    }
    
    @Test func multiWordVariableWithThreeWords() async throws {
        let results = evaluate("my favorite number = 42\nmy favorite number * 2")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 42)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 84)
    }
    
    @Test func singleWordVariableStillWorks() async throws {
        let results = evaluate("x = 10\nx + 5")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 10)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 15)
    }

}
