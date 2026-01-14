//
//  ExpressionEnginePercentTests.swift
//  limeTests
//

import Testing
import Foundation
@testable import lime

struct ExpressionEnginePercentTests {

    // MARK: - Basic Percent Literal
    
    @Test func percentLiteral() async throws {
        let results = evaluate("5%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 5)
        #expect(results.lineResults[0].value?.displayString == "5%")
    }
    
    @Test func percentLiteralWithDecimal() async throws {
        let results = evaluate("12.5%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "12.5"))
        #expect(results.lineResults[0].value?.displayString == "12.5%")
    }
    
    // MARK: - Percent Of
    
    @Test func percentOfBasic() async throws {
        let results = evaluate("20% of 10")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }
    
    @Test func percentOfWithLargerNumbers() async throws {
        let results = evaluate("15% of 200")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 30)
    }
    
    @Test func percentOfCurrency() async throws {
        let results = evaluate("10% of $50")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 5)
        #expect(results.lineResults[0].value?.displayString == "$5")
    }
    
    // MARK: - Percent On (Add)
    
    @Test func percentOnBasic() async throws {
        let results = evaluate("5% on 30")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "31.5"))
    }
    
    @Test func percentOnCurrency() async throws {
        let results = evaluate("10% on $100")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 110)
        #expect(results.lineResults[0].value?.displayString == "$110")
    }
    
    // MARK: - Percent Off (Subtract)
    
    @Test func percentOffBasic() async throws {
        let results = evaluate("6% off 40")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "37.6"))
    }
    
    @Test func percentOffCurrency() async throws {
        let results = evaluate("10% off $200")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 180)
        #expect(results.lineResults[0].value?.displayString == "$180")
    }
    
    // MARK: - Shorthand Forms
    
    @Test func shorthandAdd() async throws {
        let results = evaluate("30 + 5%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "31.5"))
    }
    
    @Test func shorthandSubtract() async throws {
        let results = evaluate("40 - 6%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "37.6"))
    }
    
    @Test func shorthandAddCurrency() async throws {
        let results = evaluate("$100 + 10%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 110)
        #expect(results.lineResults[0].value?.displayString == "$110")
    }
    
    @Test func shorthandSubtractCurrency() async throws {
        let results = evaluate("$200 - 10%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 180)
        #expect(results.lineResults[0].value?.displayString == "$180")
    }
    
    @Test func shorthandMultiply() async throws {
        let results = evaluate("10 * 20%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }
    
    @Test func shorthandMultiplyCurrency() async throws {
        let results = evaluate("$50 * 10%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 5)
        #expect(results.lineResults[0].value?.displayString == "$5")
    }
    
    @Test func shorthandMultiplyUnicodeSymbol() async throws {
        let results = evaluate("10 × 20%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }
    
    @Test func shorthandMultiplyUnicodeSymbolCurrency() async throws {
        let results = evaluate("$50 × 10%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 5)
        #expect(results.lineResults[0].value?.displayString == "$5")
    }
    
    // MARK: - Precedence
    
    @Test func percentOfPrecedence() async throws {
        // 5% of 20 = 1, then 10 + 1 = 11
        let results = evaluate("10 + 5% of 20")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 11)
    }
    
    @Test func percentOfMultiplicationPrecedence() async throws {
        // 50% of 10 = 5, then 5 * 2 = 10
        let results = evaluate("50% of 10 * 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 10)
    }
    
    // MARK: - Case Insensitivity
    
    @Test func percentOfCaseInsensitive() async throws {
        let results = evaluate("20% OF 10")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }
    
    @Test func percentOnCaseInsensitive() async throws {
        let results = evaluate("5% ON 30")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "31.5"))
    }
    
    @Test func percentOffCaseInsensitive() async throws {
        let results = evaluate("6% OFF 40")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "37.6"))
    }
    
    // MARK: - Negative Percent
    
    @Test func negativePercent() async throws {
        let results = evaluate("-5%")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -5)
        #expect(results.lineResults[0].value?.displayString == "-5%")
    }
    
    @Test func negativePercentOf() async throws {
        // -20% of 10 = -2
        let results = evaluate("-20% of 10")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -2)
    }

}
