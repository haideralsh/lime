import Foundation

public enum TokenKind: Equatable {
    case number(Decimal)
    case identifier(String)
    case plus
    case minus
    case star
    case slash
    case mod
    case caret
    case percent
    case equal
    case leftParen
    case rightParen
    case comment(String)
    case sumAggregate
    case totalAggregate
    case avgAggregate
    case averageAggregate
    case prevAggregate
    case subtotalAggregate
    case currencySymbol(String)
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
