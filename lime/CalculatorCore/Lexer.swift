import Foundation

public final class Lexer {
    private let source: String
    private var currentIndex: String.Index
    private var utf16Offset: Int = 0
    
    public init(source: String) {
        self.source = source
        self.currentIndex = source.startIndex
    }
    
    public func lexAll() -> [Token] {
        var tokens: [Token] = []
        while true {
            let token = nextToken()
            tokens.append(token)
            if case .eof = token.kind {
                break
            }
        }
        return tokens
    }
    
    public func nextToken() -> Token {
        skipWhitespace()
        
        guard currentIndex < source.endIndex else {
            return Token(kind: .eof, range: NSRange(location: utf16Offset, length: 0))
        }
        
        let char = source[currentIndex]
        let startOffset = utf16Offset
        
        if char == "#" {
            return lexComment(startOffset: startOffset)
        }
        
        if char.isNumber || (char == "." && peek(offset: 1)?.isNumber == true) {
            return lexNumber(startOffset: startOffset)
        }
        
        if char.isLetter || char == "_" {
            return lexIdentifier(startOffset: startOffset)
        }
        
        advance()
        let range = NSRange(location: startOffset, length: utf16Offset - startOffset)
        
        switch char {
        case "+": return Token(kind: .plus, range: range)
        case "-": return Token(kind: .minus, range: range)
        case "*": return Token(kind: .star, range: range)
        case "/": return Token(kind: .slash, range: range)
        case "=": return Token(kind: .equal, range: range)
        case "(": return Token(kind: .leftParen, range: range)
        case ")": return Token(kind: .rightParen, range: range)
        default:
            return Token(kind: .identifier(String(char)), range: range)
        }
    }
    
    private func lexNumber(startOffset: Int) -> Token {
        var numberString = ""
        var hasDecimalPoint = false
        
        while currentIndex < source.endIndex {
            let char = source[currentIndex]
            if char.isNumber {
                numberString.append(char)
                advance()
            } else if char == "," {
                // Allow commas as thousand separators (skip them in the number string)
                advance()
            } else if char == "." && !hasDecimalPoint {
                hasDecimalPoint = true
                numberString.append(char)
                advance()
            } else {
                break
            }
        }
        
        let value = Decimal(string: numberString) ?? 0
        let range = NSRange(location: startOffset, length: utf16Offset - startOffset)
        return Token(kind: .number(value), range: range)
    }
    
    private func lexIdentifier(startOffset: Int) -> Token {
        var identifier = ""
        
        while currentIndex < source.endIndex {
            let char = source[currentIndex]
            if char.isLetter || char.isNumber || char == "_" {
                identifier.append(char)
                advance()
            } else {
                break
            }
        }
        
        let range = NSRange(location: startOffset, length: utf16Offset - startOffset)
        return Token(kind: .identifier(identifier), range: range)
    }
    
    private func lexComment(startOffset: Int) -> Token {
        var commentString = ""
        
        // Skip the '#' character
        advance()
        
        // Consume all characters until end of line or end of source
        while currentIndex < source.endIndex {
            let char = source[currentIndex]
            if char == "\n" || char == "\r" {
                break
            }
            commentString.append(char)
            advance()
        }
        
        let range = NSRange(location: startOffset, length: utf16Offset - startOffset)
        return Token(kind: .comment(commentString), range: range)
    }
    
    private func skipWhitespace() {
        while currentIndex < source.endIndex {
            let char = source[currentIndex]
            if char == " " || char == "\t" {
                advance()
            } else {
                break
            }
        }
    }
    
    private func advance() {
        if currentIndex < source.endIndex {
            utf16Offset += source[currentIndex].utf16.count
            currentIndex = source.index(after: currentIndex)
        }
    }
    
    private func peek(offset: Int = 0) -> Character? {
        var index = currentIndex
        for _ in 0..<offset {
            guard index < source.endIndex else { return nil }
            index = source.index(after: index)
        }
        guard index < source.endIndex else { return nil }
        return source[index]
    }
}
