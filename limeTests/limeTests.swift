//
//  limeTests.swift
//  limeTests
//
//  Created by Haider on 2025-12-31.
//

import Testing
import Foundation
@testable import lime

struct limeTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testMultiWordVariableAssignment() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my age = 20")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 20)
    }
    
    @Test func testMultiWordVariableUsage() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my age = 20\nmy age + 5")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 20)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 25)
    }
    
    @Test func testMultiWordVariableWithThreeWords() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("my favorite number = 42\nmy favorite number * 2")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 42)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 84)
    }
    
    @Test func testSingleWordVariableStillWorks() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("x = 10\nx + 5")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 10)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 15)
    }
    
    // MARK: - Currency Tests
    
    @Test func testCurrencyParsing() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[0].value?.displayString == "$100")
    }
    
    @Test func testCurrencyWithDecimals() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$1,234.56")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "1234.56"))
        #expect(results.lineResults[0].value?.displayString == "$1,234.56")
    }
    
    @Test func testCurrencyAddition() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100 + $50")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 150)
        #expect(results.lineResults[0].value?.displayString == "$150")
    }
    
    @Test func testCurrencyPlusScalar() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100 + 20")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 120)
        #expect(results.lineResults[0].value?.displayString == "$120")
    }
    
    @Test func testScalarPlusCurrency() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("20 + $100")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 120)
        #expect(results.lineResults[0].value?.displayString == "$120")
    }
    
    @Test func testCurrencyMultiplication() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100 * 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 200)
        #expect(results.lineResults[0].value?.displayString == "$200")
    }
    
    @Test func testCurrencyDivision() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100 / 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 50)
        #expect(results.lineResults[0].value?.displayString == "$50")
    }
    
    @Test func testCurrencyDivisionByMoney() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100 / $25")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 4)
        #expect(results.lineResults[0].value?.displayString == "4")
    }
    
    @Test func testNegativeCurrency() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("-$50")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -50)
        #expect(results.lineResults[0].value?.displayString == "$-50")
    }
    
    @Test func testCurrencyInSumAggregate() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100\n$50\n=sum")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }
    
    @Test func testCurrencyMixedWithScalarInAggregate() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100\n50\n=sum")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }
    
    @Test func testCurrencyInAvgAggregate() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100\n$200\n=avg")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }
    
    // MARK: - =prev Tests
    
    @Test func testPrevBasic() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("100\n=prev + 50")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 150)
    }
    
    @Test func testPrevWithVariable() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("cost = 20 + 56\ndiscounted = =prev - 20")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[0].value?.asDecimal == 76)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 56)
    }
    
    @Test func testPrevSkipsEmptyLines() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("100\n\n=prev")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 100)
    }
    
    @Test func testPrevSkipsComments() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("100\n# this is a comment\n=prev")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 100)
    }
    
    @Test func testPrevOnFirstLine() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("=prev + 10")
        
        #expect(results.lineResults.count == 1)
        // Should return nothing (no result, no error) when =prev is on first line
        #expect(results.lineResults[0].value == nil)
        #expect(results.lineResults[0].error == nil)
    }
    
    @Test func testPrevWithCurrency() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("$100\n=prev - 20")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 80)
        #expect(results.lineResults[1].value?.displayString == "$80")
    }
    
    @Test func testPrevChained() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("100\n=prev + 10\n=prev * 2")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[1].value?.asDecimal == 110)
        #expect(results.lineResults[2].value?.asDecimal == 220)
    }
    
    @Test func testPrevStandalone() async throws {
        let engine = ExpressionEngine()
        let results = engine.evaluateAll("42\n=prev")
        
        #expect(results.lineResults.count == 2)
        #expect(results.lineResults[1].error == nil)
        #expect(results.lineResults[1].value?.asDecimal == 42)
    }

}
