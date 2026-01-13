//
//  ExpressionEngineModuloTests.swift
//  limeTests
//
//  The 'mod' operator uses truncated division semantics (matching Swift's % operator).
//  The sign of the result always matches the sign of the dividend (left operand).
//  Examples:
//    5 mod 2 = 1      (5 = 2*2 + 1)
//    (-5) mod 2 = -1  (-5 = 2*(-2) + (-1))
//    5 mod (-2) = 1   (5 = (-2)*(-2) + 1)
//    (-5) mod (-2) = -1  (-5 = (-2)*2 + (-1))
//

import Testing
import Foundation
@testable import lime

struct ExpressionEngineModuloTests {

    @Test func moduloBasic() async throws {
        let results = evaluate("5 mod 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 1)
    }
    
    @Test func moduloWithDecimals() async throws {
        let results = evaluate("5.5 mod 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == Decimal(string: "1.5"))
    }
    
    @Test func moduloNegativeDividend() async throws {
        let results = evaluate("-5 mod 2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -1)
    }
    
    @Test func moduloNegativeDivisor() async throws {
        let results = evaluate("5 mod -2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 1)
    }
    
    @Test func moduloBothNegative() async throws {
        let results = evaluate("-5 mod -2")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == -1)
    }
    
    @Test func moduloDivisionByZero() async throws {
        let results = evaluate("5 mod 0")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error != nil)
    }
    
    @Test func moduloPrecedence() async throws {
        let results = evaluate("10 mod 3 + 1")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }
    
    @Test func moduloCaseInsensitive() async throws {
        let results = evaluate("17 MOD 5")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].error == nil)
        #expect(results.lineResults[0].value?.asDecimal == 2)
    }

}
