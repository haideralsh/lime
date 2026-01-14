import Foundation

public enum ParseError: Error, LocalizedError {
    case unexpectedToken(Token, expected: String)
    case unexpectedEndOfInput
    case invalidExpression(NSRange)
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedToken(_, let expected):
            return "Unexpected token, expected \(expected)"
        case .unexpectedEndOfInput:
            return "Unexpected end of input"
        case .invalidExpression:
            return "Invalid expression"
        }
    }
    
    public var range: NSRange? {
        switch self {
        case .unexpectedToken(let token, _):
            return token.range
        case .unexpectedEndOfInput:
            return nil
        case .invalidExpression(let range):
            return range
        }
    }
}

public final class Parser {
    private let tokens: [Token]
    private var index: Int = 0
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    private var currentToken: Token {
        guard index < tokens.count else {
            return Token(kind: .eof, range: NSRange(location: 0, length: 0))
        }
        return tokens[index]
    }
    
    private func advance() {
        if index < tokens.count {
            index += 1
        }
    }
    
    private func peek() -> Token {
        currentToken
    }
    
    private func collectIdentifierSequence() -> (name: String, range: NSRange, count: Int)? {
        guard case .identifier(let firstName) = currentToken.kind else {
            return nil
        }
        
        var names: [String] = [firstName]
        let startRange = currentToken.range
        var endRange = currentToken.range
        var tokenCount = 1
        
        var lookAhead = index + 1
        while lookAhead < tokens.count {
            let token = tokens[lookAhead]
            if case .identifier(let name) = token.kind {
                names.append(name)
                endRange = token.range
                tokenCount += 1
                lookAhead += 1
            } else {
                break
            }
        }
        
        let combinedName = names.joined(separator: " ")
        let combinedRange = NSRange(
            location: startRange.location,
            length: endRange.location + endRange.length - startRange.location
        )
        
        return (combinedName, combinedRange, tokenCount)
    }
    
    public func parseLine() throws -> Statement? {
        while case .comment = currentToken.kind {
            advance()
        }
        
        if case .eof = currentToken.kind {
            return nil
        }
        
        if let (name, nameRange, tokenCount) = collectIdentifierSequence() {
            let afterIdentifiers = index + tokenCount
            if afterIdentifiers < tokens.count, case .equal = tokens[afterIdentifiers].kind {
                for _ in 0..<tokenCount {
                    advance()
                }
                advance() // skip '='
                let expr = try parseExpression()
                return .assignment(AssignmentStmt(
                    name: name,
                    nameRange: nameRange,
                    value: expr
                ))
            }
        }
        
        let expr = try parseExpression()
        return .expression(expr)
    }
    
    private func parseExpression() throws -> Expr {
        try parseAdditive()
    }
    
    private func parseAdditive() throws -> Expr {
        var left = try parseMultiplicative()
        
        while true {
            if case .identifier(let ident) = currentToken.kind {
                let lower = ident.lowercased()
                if lower == "on" || lower == "off" {
                    let kind: PercentAdjustKind = lower == "on" ? .on : .off
                    advance()
                    let right = try parseMultiplicative()
                    let range = NSRange(
                        location: exprRange(left).location,
                        length: exprRange(right).location + exprRange(right).length - exprRange(left).location
                    )
                    
                    left = PercentAdjustExpr(kind: kind, percent: left, base: right, range: range)
                    continue
                }
            }
            
            let isAdd: Bool
            switch currentToken.kind {
            case .plus:
                isAdd = true
            case .minus:
                isAdd = false
            default:
                return left
            }
            
            advance()
            let right = try parseMultiplicative()
            let range = NSRange(
                location: exprRange(left).location,
                length: exprRange(right).location + exprRange(right).length - exprRange(left).location
            )
            
            if right is PercentExpr {
                let kind: PercentAdjustKind = isAdd ? .on : .off
                left = PercentAdjustExpr(kind: kind, percent: right, base: left, range: range)
            } else {
                let op: BinaryOp = isAdd ? .add : .subtract
                left = BinaryExpr(op: op, left: left, right: right, range: range)
            }
        }
    }
    
    private func parseMultiplicative() throws -> Expr {
        var left = try parseExponentiation()
        
        while true {
            if case .identifier(let ident) = currentToken.kind, ident.lowercased() == "of" {
                advance()
                let right = try parseExponentiation()
                let range = NSRange(
                    location: exprRange(left).location,
                    length: exprRange(right).location + exprRange(right).length - exprRange(left).location
                )
                left = PercentOfExpr(percent: left, base: right, range: range)
                continue
            }
            
            let op: BinaryOp
            switch currentToken.kind {
            case .star:
                op = .multiply
            case .slash:
                op = .divide
            case .mod:
                op = .modulo
            default:
                return left
            }
            
            advance()
            let right = try parseExponentiation()
            let range = NSRange(
                location: exprRange(left).location,
                length: exprRange(right).location + exprRange(right).length - exprRange(left).location
            )
            
            if op == .multiply && right is PercentExpr {
                left = PercentOfExpr(percent: right, base: left, range: range)
            } else {
                left = BinaryExpr(op: op, left: left, right: right, range: range)
            }
        }
    }
    
    private func parseExponentiation() throws -> Expr {
        let left = try parseUnary()
        
        // Exponentiation is right-associative
        if case .caret = currentToken.kind {
            advance()
            let right = try parseExponentiation()
            let range = NSRange(
                location: exprRange(left).location,
                length: exprRange(right).location + exprRange(right).length - exprRange(left).location
            )
            return BinaryExpr(op: .power, left: left, right: right, range: range)
        }
        
        return left
    }
    
    private func parseUnary() throws -> Expr {
        if case .minus = currentToken.kind {
            let opToken = currentToken
            advance()
            let operand = try parseUnary()
            let range = NSRange(
                location: opToken.range.location,
                length: exprRange(operand).location + exprRange(operand).length - opToken.range.location
            )
            return UnaryExpr(op: .negate, operand: operand, range: range)
        }
        
        return try parsePostfix()
    }
    
    private func parsePostfix() throws -> Expr {
        var expr = try parsePrimary()
        
        while case .percent = currentToken.kind {
            let percentToken = currentToken
            advance()
            let range = NSRange(
                location: exprRange(expr).location,
                length: percentToken.range.location + percentToken.range.length - exprRange(expr).location
            )
            expr = PercentExpr(operand: expr, range: range)
        }
        
        return expr
    }
    
    private func parsePrimary() throws -> Expr {
        let token = currentToken
        
        switch token.kind {
        case .number(let value):
            advance()
            return NumberExpr(value: value, range: token.range)
            
        case .currencySymbol(let symbol):
            let symbolToken = token
            advance()
            
            guard case .number(let value) = currentToken.kind else {
                throw ParseError.unexpectedToken(currentToken, expected: "number after currency symbol")
            }
            let numberToken = currentToken
            advance()
            
            let combinedRange = NSRange(
                location: symbolToken.range.location,
                length: numberToken.range.location + numberToken.range.length - symbolToken.range.location
            )
            return CurrencyNumberExpr(value: value, currencySymbol: symbol, range: combinedRange)
            
        case .identifier:
            if let (name, range, tokenCount) = collectIdentifierSequence() {
                for _ in 0..<tokenCount {
                    advance()
                }
                return VariableExpr(name: name, range: range)
            }
            advance()
            if case .identifier(let name) = token.kind {
                return VariableExpr(name: name, range: token.range)
            }
            throw ParseError.unexpectedToken(token, expected: "identifier")
            
        case .sumAggregate:
            advance()
            return BuiltinAggregateExpr(kind: .sum, range: token.range)
            
        case .totalAggregate:
            advance()
            return BuiltinAggregateExpr(kind: .total, range: token.range)
            
        case .avgAggregate:
            advance()
            return BuiltinAggregateExpr(kind: .avg, range: token.range)
            
        case .averageAggregate:
            advance()
            return BuiltinAggregateExpr(kind: .average, range: token.range)
            
        case .prevAggregate:
            advance()
            return BuiltinAggregateExpr(kind: .prev, range: token.range)
            
        case .leftParen:
            let leftParen = token
            advance()
            let inner = try parseExpression()
            
            guard case .rightParen = currentToken.kind else {
                throw ParseError.unexpectedToken(currentToken, expected: ")")
            }
            let rightParen = currentToken
            advance()
            
            let range = NSRange(
                location: leftParen.range.location,
                length: rightParen.range.location + rightParen.range.length - leftParen.range.location
            )
            return ParenExpr(inner: inner, range: range)
            
        case .eof:
            throw ParseError.unexpectedEndOfInput
            
        default:
            throw ParseError.unexpectedToken(token, expected: "number, variable, =sum, =total, =avg, =average, =prev, or (")
        }
    }
    
    private func exprRange(_ expr: Expr) -> NSRange {
        switch expr {
        case let e as NumberExpr: return e.range
        case let e as CurrencyNumberExpr: return e.range
        case let e as VariableExpr: return e.range
        case let e as BinaryExpr: return e.range
        case let e as UnaryExpr: return e.range
        case let e as ParenExpr: return e.range
        case let e as BuiltinAggregateExpr: return e.range
        case let e as PercentExpr: return e.range
        case let e as PercentOfExpr: return e.range
        case let e as PercentAdjustExpr: return e.range
        default: return NSRange(location: 0, length: 0)
        }
    }
}
