import Foundation

public enum ParseError: Error, LocalizedError {
    case unexpectedToken(Token, expected: String)
    case unexpectedEndOfInput
    case invalidExpression(NSRange)
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedToken(let token, let expected):
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
        var startRange = currentToken.range
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
        // Skip any comment tokens
        while case .comment = currentToken.kind {
            advance()
        }
        
        if case .eof = currentToken.kind {
            return nil
        }
        
        if let (name, nameRange, tokenCount) = collectIdentifierSequence() {
            let afterIdentifiers = index + tokenCount
            if afterIdentifiers < tokens.count, case .equal = tokens[afterIdentifiers].kind {
                // Advance past all identifier tokens and the '='
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
            let op: BinaryOp
            switch currentToken.kind {
            case .plus:
                op = .add
            case .minus:
                op = .subtract
            default:
                return left
            }
            
            advance()
            let right = try parseMultiplicative()
            let range = NSRange(
                location: exprRange(left).location,
                length: exprRange(right).location + exprRange(right).length - exprRange(left).location
            )
            left = BinaryExpr(op: op, left: left, right: right, range: range)
        }
    }
    
    private func parseMultiplicative() throws -> Expr {
        var left = try parseUnary()
        
        while true {
            let op: BinaryOp
            switch currentToken.kind {
            case .star:
                op = .multiply
            case .slash:
                op = .divide
            default:
                return left
            }
            
            advance()
            let right = try parseUnary()
            let range = NSRange(
                location: exprRange(left).location,
                length: exprRange(right).location + exprRange(right).length - exprRange(left).location
            )
            left = BinaryExpr(op: op, left: left, right: right, range: range)
        }
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
        
        return try parsePrimary()
    }
    
    private func parsePrimary() throws -> Expr {
        let token = currentToken
        
        switch token.kind {
        case .number(let value):
            advance()
            return NumberExpr(value: value, range: token.range)
            
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
            throw ParseError.unexpectedToken(token, expected: "number, variable, or (")
        }
    }
    
    private func exprRange(_ expr: Expr) -> NSRange {
        switch expr {
        case let e as NumberExpr: return e.range
        case let e as VariableExpr: return e.range
        case let e as BinaryExpr: return e.range
        case let e as UnaryExpr: return e.range
        case let e as ParenExpr: return e.range
        default: return NSRange(location: 0, length: 0)
        }
    }
}
