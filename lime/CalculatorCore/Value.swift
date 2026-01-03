import Foundation

public enum UnitKind {
    case scalar
    case length
    case mass
    case currency
}

public struct Unit: Equatable {
    public let name: String
    public let kind: UnitKind
    public let toBaseFactor: Decimal?
    
    public init(name: String, kind: UnitKind, toBaseFactor: Decimal? = nil) {
        self.name = name
        self.kind = kind
        self.toBaseFactor = toBaseFactor
    }
}

public struct Quantity: Equatable {
    public var magnitude: Decimal
    public var unit: Unit?
    
    public init(magnitude: Decimal, unit: Unit? = nil) {
        self.magnitude = magnitude
        self.unit = unit
    }
    
    public static func scalar(_ value: Decimal) -> Quantity {
        Quantity(magnitude: value, unit: nil)
    }
}

public enum Value: Equatable {
    case quantity(Quantity)
    
    public var asDecimal: Decimal? {
        switch self {
        case .quantity(let q):
            return q.magnitude
        }
    }
    
    public var displayString: String {
        switch self {
        case .quantity(let q):
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 10
            formatter.minimumFractionDigits = 0
            
            let number = NSDecimalNumber(decimal: q.magnitude)
            let formatted = formatter.string(from: number) ?? "\(q.magnitude)"
            
            if let unit = q.unit {
                return "\(formatted) \(unit.name)"
            }
            return formatted
        }
    }
}
