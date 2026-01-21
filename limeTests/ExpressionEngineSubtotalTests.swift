//
//  ExpressionEngineSubtotalTests.swift
//  limeTests
//

import Testing
import Foundation
@testable import lime

struct ExpressionEngineSubtotalTests {

    @Test func subtotalBasic() async throws {
        let results = evaluate("10\n20\n30\n=subtotal")
        
        #expect(results.lineResults.count == 4)
        #expect(results.lineResults[0].value?.asDecimal == 10)
        #expect(results.lineResults[1].value?.asDecimal == 20)
        #expect(results.lineResults[2].value?.asDecimal == 30)
        #expect(results.lineResults[3].value?.asDecimal == 60)
    }
    
    @Test func subtotalResetsAfterPrevious() async throws {
        let results = evaluate("10\n20\n=subtotal\n5\n15\n=subtotal")
        
        #expect(results.lineResults.count == 6)
        #expect(results.lineResults[2].value?.asDecimal == 30)
        #expect(results.lineResults[5].value?.asDecimal == 20)
    }
    
    @Test func subtotalWithCurrency() async throws {
        let results = evaluate("$10\n$20\n$30\n=subtotal")
        
        #expect(results.lineResults.count == 4)
        #expect(results.lineResults[3].value?.asDecimal == 60)
        #expect(results.lineResults[3].value?.displayString == "$60")
    }
    
    @Test func subtotalInExpression() async throws {
        let results = evaluate("10\n20\n=subtotal + 5")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].value?.asDecimal == 35)
    }
    
    @Test func subtotalAtStart() async throws {
        let results = evaluate("=subtotal")
        
        #expect(results.lineResults.count == 1)
        #expect(results.lineResults[0].value?.asDecimal == 0)
    }
    
    @Test func subtotalSkipsEmptyLines() async throws {
        let results = evaluate("10\n\n20\n=subtotal")
        
        #expect(results.lineResults.count == 4)
        #expect(results.lineResults[3].value?.asDecimal == 30)
    }
    
    @Test func subtotalSkipsComments() async throws {
        let results = evaluate("10\n# comment\n20\n=subtotal")
        
        #expect(results.lineResults.count == 4)
        #expect(results.lineResults[3].value?.asDecimal == 30)
    }
    
    @Test func subtotalDoesNotAffectGlobalSum() async throws {
        let results = evaluate("10\n20\n=subtotal\n5")
        
        #expect(results.sum == 35)
    }
    
    @Test func multipleSubtotalsChained() async throws {
        let results = evaluate("100\n=subtotal\n50\n=subtotal\n25\n=subtotal")
        
        #expect(results.lineResults.count == 6)
        #expect(results.lineResults[1].value?.asDecimal == 100)
        #expect(results.lineResults[3].value?.asDecimal == 50)
        #expect(results.lineResults[5].value?.asDecimal == 25)
    }
    
    @Test func subtotalAssignment() async throws {
        let results = evaluate("10\n20\npartial = =subtotal")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].value?.asDecimal == 30)
    }
    
    @Test func subtotalMultiplied() async throws {
        let results = evaluate("10\n20\n=subtotal * 2")
        
        #expect(results.lineResults.count == 3)
        #expect(results.lineResults[2].value?.asDecimal == 60)
    }

}
