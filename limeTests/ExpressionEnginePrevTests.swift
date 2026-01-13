//
//  ExpressionEnginePrevTests.swift
//  limeTests
//

import Testing
import Foundation
@testable import lime

struct ExpressionEnginePrevTests {

    @Test func prevBasic() async throws {
        let results = evaluate("100\n=prev + 50")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 150)
    }
    
    @Test func prevWithVariable() async throws {
        let results = evaluate("cost = 20 + 56\ndiscounted = =prev - 20")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].value?.asDecimal == 76)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 56)
    }
    
    @Test func prevSkipsEmptyLines() async throws {
        let results = evaluate("100\n\n=prev")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 100)
    }
    
    @Test func prevSkipsComments() async throws {
        let results = evaluate("100\n# this is a comment\n=prev")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 100)
    }
    
    @Test func prevOnFirstLine() async throws {
        let results = evaluate("=prev + 10")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].value == nil)
        #expect(results.lineResults[0].error == nil)
    }
    
    @Test func prevWithCurrency() async throws {
        let results = evaluate("$100\n=prev - 20")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 80)
        #expect(results.lineResults[1].value?.displayString == "$80")
    }
    
    @Test func prevChained() async throws {
        let results = evaluate("100\n=prev + 10\n=prev * 2")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[1].value?.asDecimal == 110)
        #expect(results.lineResults[2].value?.asDecimal == 220)
    }
    
    @Test func prevStandalone() async throws {
        let results = evaluate("42\n=prev")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 42)
    }

}
