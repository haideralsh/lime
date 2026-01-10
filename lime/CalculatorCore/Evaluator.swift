import Foundation

public enum BuiltinAggregateName {
    public static let sum = "=sum"
    public static let avg = "=avg"
}

public enum EvalError: Error, LocalizedError {
    case undefinedVariable(String, range: NSRange?)
    case divisionByZero(range: NSRange?)
    case typeMismatch(String, range: NSRange?)
    
    public var errorDescription: String? {
        switch self {
        case .undefinedVariable(let name, _):
            return "Undefined variable: \(name)"
        case .divisionByZero:
            return "Division by zero"
        case .typeMismatch(let message, _):
            return message
        }
    }
    
    public var range: NSRange? {
        switch self {
        case .undefinedVariable(_, let range): return range
        case .divisionByZero(let range): return range
        case .typeMismatch(_, let range): return range
        }
    }
}

public final class Evaluator {
    private let environment: Environment
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    public func evaluate(_ statement: Statement) throws -> Value? {
        switch statement {
        case .expression(let expr):
            return try eval(expr)
        case .assignment(let stmt):
            let val = try eval(stmt.value)
            environment[stmt.name] = val
            return val
        }
    }
    
    private func eval(_ expr: Expr) throws -> Value {
        switch expr {
        case let n as NumberExpr:
            return .quantity(.scalar(n.value))
            
        case let v as VariableExpr:
            guard let value = environment[v.name] else {
                throw EvalError.undefinedVariable(v.name, range: v.range)
            }
            return value
            
        case let b as BinaryExpr:
            let leftVal = try eval(b.left)
            let rightVal = try eval(b.right)
            
            guard let leftDec = leftVal.asDecimal,
                  let rightDec = rightVal.asDecimal else {
                throw EvalError.typeMismatch("Cannot perform arithmetic", range: b.range)
            }
            
            let result: Decimal
            switch b.op {
            case .add:
                result = leftDec + rightDec
            case .subtract:
                result = leftDec - rightDec
            case .multiply:
                result = leftDec * rightDec
            case .divide:
                if rightDec == 0 {
                    throw EvalError.divisionByZero(range: b.range)
                }
                result = leftDec / rightDec
            }
            return .quantity(.scalar(result))
            
        case let u as UnaryExpr:
            let operandVal = try eval(u.operand)
            guard let dec = operandVal.asDecimal else {
                throw EvalError.typeMismatch("Cannot negate value", range: u.range)
            }
            
            switch u.op {
            case .negate:
                return .quantity(.scalar(-dec))
            }
            
        case let p as ParenExpr:
            return try eval(p.inner)
            
        case let a as BuiltinAggregateExpr:
            let key: String
            let displayName: String
            switch a.kind {
            case .sum:
                key = BuiltinAggregateName.sum
                displayName = "=sum"
            case .avg:
                key = BuiltinAggregateName.avg
                displayName = "=avg"
            }
            guard let value = environment[key] else {
                throw EvalError.undefinedVariable(displayName, range: a.range)
            }
            return value
            
        default:
            throw EvalError.typeMismatch("Unknown expression type", range: nil)
        }
    }
}
