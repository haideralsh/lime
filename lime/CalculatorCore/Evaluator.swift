import Foundation

public enum BuiltinAggregateName {
    public static let sum = "=sum"
    public static let avg = "=avg"
    public static let prev = "=prev"
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
            
        case let c as CurrencyNumberExpr:
            guard let unit = Unit.currency(forSymbol: c.currencySymbol) else {
                throw EvalError.typeMismatch("Unknown currency symbol \(c.currencySymbol)", range: c.range)
            }
            return .quantity(Quantity(magnitude: c.value, unit: unit))
            
        case let v as VariableExpr:
            guard let value = environment[v.name] else {
                throw EvalError.undefinedVariable(v.name, range: v.range)
            }
            return value
            
        case let b as BinaryExpr:
            let leftVal = try eval(b.left)
            let rightVal = try eval(b.right)
            
            guard case .quantity(let lq) = leftVal,
                  case .quantity(let rq) = rightVal else {
                throw EvalError.typeMismatch("Cannot perform arithmetic", range: b.range)
            }
            
            let resultQuantity: Quantity
            switch b.op {
            case .add:
                resultQuantity = try add(lq, rq, range: b.range)
            case .subtract:
                resultQuantity = try subtract(lq, rq, range: b.range)
            case .multiply:
                resultQuantity = try multiply(lq, rq, range: b.range)
            case .divide:
                resultQuantity = try divide(lq, rq, range: b.range)
            case .modulo:
                resultQuantity = try modulo(lq, rq, range: b.range)
            case .power:
                resultQuantity = try power(lq, rq, range: b.range)
            }
            return .quantity(resultQuantity)
            
        case let u as UnaryExpr:
            let operandVal = try eval(u.operand)
            guard case .quantity(var q) = operandVal else {
                throw EvalError.typeMismatch("Cannot negate value", range: u.range)
            }
            
            switch u.op {
            case .negate:
                q.magnitude = -q.magnitude
                return .quantity(q)
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
            case .total:
                key = BuiltinAggregateName.sum
                displayName = "=total"
            case .avg:
                key = BuiltinAggregateName.avg
                displayName = "=avg"
            case .average:
                key = BuiltinAggregateName.avg
                displayName = "=average"
            case .prev:
                key = BuiltinAggregateName.prev
                displayName = "=prev"
            }
            guard let value = environment[key] else {
                throw EvalError.undefinedVariable(displayName, range: a.range)
            }
            return value
            
        default:
            throw EvalError.typeMismatch("Unknown expression type", range: nil)
        }
    }
    
    private func add(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        let lu = lhs.unit
        let ru = rhs.unit
        
        if lu?.kind == .currency || ru?.kind == .currency {
            if let lu = lu, let ru = ru, lu != ru {
                throw EvalError.typeMismatch("Cannot add values with different currencies", range: range)
            }
            let unit = lu ?? ru
            return Quantity(magnitude: lhs.magnitude + rhs.magnitude, unit: unit)
        }
        
        if lu == ru {
            return Quantity(magnitude: lhs.magnitude + rhs.magnitude, unit: lu)
        }
        if lu == nil {
            return Quantity(magnitude: lhs.magnitude + rhs.magnitude, unit: ru)
        }
        if ru == nil {
            return Quantity(magnitude: lhs.magnitude + rhs.magnitude, unit: lu)
        }
        
        throw EvalError.typeMismatch("Cannot add values with different units", range: range)
    }
    
    private func subtract(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        var negRhs = rhs
        negRhs.magnitude = -rhs.magnitude
        return try add(lhs, negRhs, range: range)
    }
    
    private func multiply(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        let lu = lhs.unit
        let ru = rhs.unit
        
        if lu?.kind == .currency && ru == nil {
            return Quantity(magnitude: lhs.magnitude * rhs.magnitude, unit: lu)
        }
        if ru?.kind == .currency && lu == nil {
            return Quantity(magnitude: lhs.magnitude * rhs.magnitude, unit: ru)
        }
        
        if lu?.kind == .currency || ru?.kind == .currency {
            return Quantity(magnitude: lhs.magnitude * rhs.magnitude, unit: ru)
        }
        
        if lu == nil && ru == nil {
            return Quantity.scalar(lhs.magnitude * rhs.magnitude)
        }
        
        throw EvalError.typeMismatch("Unsupported unit multiplication", range: range)
    }
    
    private func divide(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        if rhs.magnitude == 0 {
            throw EvalError.divisionByZero(range: range)
        }
        
        let lu = lhs.unit
        let ru = rhs.unit
        
        if lu?.kind == .currency && ru == nil {
            return Quantity(magnitude: lhs.magnitude / rhs.magnitude, unit: lu)
        }
        
        if lu?.kind == .currency && ru?.kind == .currency {
            return Quantity.scalar(lhs.magnitude / rhs.magnitude)
        }
        
        if lu == nil && ru == nil {
            return Quantity.scalar(lhs.magnitude / rhs.magnitude)
        }
        
        throw EvalError.typeMismatch("Unsupported unit division", range: range)
    }
    
    private func modulo(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        if rhs.magnitude == 0 {
            throw EvalError.divisionByZero(range: range)
        }
        
        let lu = lhs.unit
        let ru = rhs.unit
        
        
        guard lu == nil && ru == nil else {
            throw EvalError.typeMismatch("Modulo operation only supported for unitless values", range: range)
        }
        
        let lhsDouble = NSDecimalNumber(decimal: lhs.magnitude).doubleValue
        let rhsDouble = NSDecimalNumber(decimal: rhs.magnitude).doubleValue
        
        let remainder = lhsDouble.truncatingRemainder(dividingBy: rhsDouble)
        
        guard remainder.isFinite else {
            throw EvalError.typeMismatch("Modulo result is not a valid number", range: range)
        }
        
        return Quantity.scalar(Decimal(remainder))
    }
    
    private func power(_ lhs: Quantity, _ rhs: Quantity, range: NSRange?) throws -> Quantity {
        guard rhs.unit == nil else {
            throw EvalError.typeMismatch("Exponent cannot have a unit", range: range)
        }
        
        let base = NSDecimalNumber(decimal: lhs.magnitude).doubleValue
        
        let exponent = NSDecimalNumber(decimal: rhs.magnitude).doubleValue
        let result = pow(base, exponent)
        
        guard result.isFinite else {
            throw EvalError.typeMismatch("Power result is not a valid number", range: range)
        }
        
        let resultDecimal = Decimal(result)
        
        if lhs.unit?.kind == .currency {
            return Quantity(magnitude: resultDecimal, unit: lhs.unit)
        }
        
        return Quantity(magnitude: resultDecimal, unit: nil)
    }
}
