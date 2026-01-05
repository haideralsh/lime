import Foundation

public enum TokenKind: Equatable {
    case number(Decimal)
    case identifier(String)
    case plus
    case minus
    case star
    case slash
    case equal
    case leftParen
    case rightParen
    case comment(String)
    case eof
}

public struct Token: Equatable {
    public let kind: TokenKind
    public let range: NSRange
    
    public init(kind: TokenKind, range: NSRange) {
        self.kind = kind
        self.range = range
    }
}
