import Foundation

public protocol Expr {}

public enum BinaryOp {
    case add
    case subtract
    case multiply
    case divide
    case modulo
    case power
}

public struct NumberExpr: Expr {
    public let value: Decimal
    public let range: NSRange
    
    public init(value: Decimal, range: NSRange) {
        self.value = value
        self.range = range
    }
}

public struct CurrencyNumberExpr: Expr {
    public let value: Decimal
    public let currencySymbol: String
    public let range: NSRange
    
    public init(value: Decimal, currencySymbol: String, range: NSRange) {
        self.value = value
        self.currencySymbol = currencySymbol
        self.range = range
    }
}

public struct VariableExpr: Expr {
    public let name: String
    public let range: NSRange
    
    public init(name: String, range: NSRange) {
        self.name = name
        self.range = range
    }
}

public struct BinaryExpr: Expr {
    public let op: BinaryOp
    public let left: Expr
    public let right: Expr
    public let range: NSRange
    
    public init(op: BinaryOp, left: Expr, right: Expr, range: NSRange) {
        self.op = op
        self.left = left
        self.right = right
        self.range = range
    }
}

public struct UnaryExpr: Expr {
    public let op: UnaryOp
    public let operand: Expr
    public let range: NSRange
    
    public init(op: UnaryOp, operand: Expr, range: NSRange) {
        self.op = op
        self.operand = operand
        self.range = range
    }
}

public enum UnaryOp {
    case negate
}

public struct ParenExpr: Expr {
    public let inner: Expr
    public let range: NSRange
    
    public init(inner: Expr, range: NSRange) {
        self.inner = inner
        self.range = range
    }
}

public struct PercentExpr: Expr {
    public let operand: Expr
    public let range: NSRange
    
    public init(operand: Expr, range: NSRange) {
        self.operand = operand
        self.range = range
    }
}

public struct PercentOfExpr: Expr {
    public let percent: Expr
    public let base: Expr
    public let range: NSRange
    
    public init(percent: Expr, base: Expr, range: NSRange) {
        self.percent = percent
        self.base = base
        self.range = range
    }
}

public enum PercentAdjustKind {
    case on
    case off
}

public struct PercentAdjustExpr: Expr {
    public let kind: PercentAdjustKind
    public let percent: Expr
    public let base: Expr
    public let range: NSRange
    
    public init(kind: PercentAdjustKind, percent: Expr, base: Expr, range: NSRange) {
        self.kind = kind
        self.percent = percent
        self.base = base
        self.range = range
    }
}

public struct BuiltinAggregateExpr: Expr {
    public enum Kind {
        case sum
        case total
        case avg
        case average
        case prev
    }
    
    public let kind: Kind
    public let range: NSRange
    
    public init(kind: Kind, range: NSRange) {
        self.kind = kind
        self.range = range
    }
}

public struct SubtotalExpr: Expr {
    public let range: NSRange
    
    public init(range: NSRange) {
        self.range = range
    }
}

public struct AssignmentStmt {
    public let name: String
    public let nameRange: NSRange
    public let value: Expr
    
    public init(name: String, nameRange: NSRange, value: Expr) {
        self.name = name
        self.nameRange = nameRange
        self.value = value
    }
}

public enum Statement {
    case expression(Expr)
    case assignment(AssignmentStmt)
}
