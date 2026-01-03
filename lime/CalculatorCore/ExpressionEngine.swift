import Foundation

public struct LineResult {
    public let lineIndex: Int
    public let sourceRange: NSRange
    public let value: Value?
    public let error: Error?
    
    public init(lineIndex: Int, sourceRange: NSRange, value: Value?, error: Error?) {
        self.lineIndex = lineIndex
        self.sourceRange = sourceRange
        self.value = value
        self.error = error
    }
    
    public var displayString: String? {
        if let value = value {
            return value.displayString
        }
        return nil
    }
    
    public var errorMessage: String? {
        error?.localizedDescription
    }
}

public final class ExpressionEngine {
    private let environment = Environment()
    
    public init() {}
    
    public func evaluateAll(_ source: String) -> [LineResult] {
        environment.clear()
        
        let lines = source.components(separatedBy: .newlines)
        var results: [LineResult] = []
        var location = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: location, length: lineLength)
            
            if lineIndex < lines.count - 1 {
                location += lineLength + 1
            }
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                results.append(LineResult(
                    lineIndex: lineIndex,
                    sourceRange: lineRange,
                    value: nil,
                    error: nil
                ))
                continue
            }
            
            let result = evaluateLine(line, lineIndex: lineIndex, sourceRange: lineRange)
            results.append(result)
        }
        
        return results
    }
    
    private func evaluateLine(_ line: String, lineIndex: Int, sourceRange: NSRange) -> LineResult {
        let lexer = Lexer(source: line)
        let tokens = lexer.lexAll()
        let parser = Parser(tokens: tokens)
        
        do {
            guard let statement = try parser.parseLine() else {
                return LineResult(
                    lineIndex: lineIndex,
                    sourceRange: sourceRange,
                    value: nil,
                    error: nil
                )
            }
            
            let evaluator = Evaluator(environment: environment)
            let value = try evaluator.evaluate(statement)
            
            return LineResult(
                lineIndex: lineIndex,
                sourceRange: sourceRange,
                value: value,
                error: nil
            )
        } catch {
            return LineResult(
                lineIndex: lineIndex,
                sourceRange: sourceRange,
                value: nil,
                error: error
            )
        }
    }
    
    public func resetEnvironment() {
        environment.clear()
    }
}
