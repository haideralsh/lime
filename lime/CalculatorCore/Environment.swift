import Foundation

public final class Environment {
    private var storage: [String: Value] = [:]
    
    public init() {}
    
    public subscript(name: String) -> Value? {
        get { storage[name] }
        set { storage[name] = newValue }
    }
    
    public func clear() {
        storage.removeAll()
    }
    
    public var allVariables: [String: Value] {
        storage
    }
}
