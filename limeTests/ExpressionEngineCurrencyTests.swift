//
//  ExpressionEngineCurrencyTests.swift
//  limeTests
//

import Testing
import Foundation
@testable import lime

struct ExpressionEngineCurrencyTests {

    @Test func currencyParsing() async throws {
        let results = evaluate("$100")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 100)
        #expect(results.lineResults[0].value?.displayString == "$100")
    }
    
    @Test func currencyWithDecimals() async throws {
        let results = evaluate("$1,234.56")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "1234.56"))
        #expect(results.lineResults[0].value?.displayString == "$1,234.56")
    }
    
    @Test func currencyAddition() async throws {
        let results = evaluate("$100 + $50")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 150)
        #expect(results.lineResults[0].value?.displayString == "$150")
    }
    
    @Test func currencyPlusScalar() async throws {
        let results = evaluate("$100 + 20")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 120)
        #expect(results.lineResults[0].value?.displayString == "$120")
    }
    
    @Test func scalarPlusCurrency() async throws {
        let results = evaluate("20 + $100")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 120)
        #expect(results.lineResults[0].value?.displayString == "$120")
    }
    
    @Test func currencyMultiplication() async throws {
        let results = evaluate("$100 * 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 200)
        #expect(results.lineResults[0].value?.displayString == "$200")
    }
    
    @Test func currencyDivision() async throws {
        let results = evaluate("$100 / 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 50)
        #expect(results.lineResults[0].value?.displayString == "$50")
    }
    
    @Test func currencyDivisionByMoney() async throws {
        let results = evaluate("$100 / $25")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 4)
        #expect(results.lineResults[0].value?.displayString == "4")
    }
    
    @Test func negativeCurrency() async throws {
        let results = evaluate("-$50")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -50)
        #expect(results.lineResults[0].value?.displayString == "$-50")
    }
    
    @Test func currencyInSumAggregate() async throws {
        let results = evaluate("$100\n$50\n=sum")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }
    
    @Test func currencyMixedWithScalarInAggregate() async throws {
        let results = evaluate("$100\n50\n=sum")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }
    
    @Test func currencyInAvgAggregate() async throws {
        let results = evaluate("$100\n$200\n=avg")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].error == nil)
        #expect(results.lineResults[2].value?.asDecimal == 150)
        #expect(results.lineResults[2].value?.displayString == "$150")
    }

}
