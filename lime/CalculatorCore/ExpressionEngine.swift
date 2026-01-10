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

private struct ParsedLine {
    let lineIndex: Int
    let sourceRange: NSRange
    let line: String
    let statement: Statement?
    let usesAggregate: Bool
    let parseError: Error?
}

public struct EvaluationResult {
    public let lineResults: [LineResult]
    public let sum: Decimal
}

public final class ExpressionEngine {
    private let environment = Environment()
    
    public init() {}
    
    public func evaluateAll(_ source: String) -> EvaluationResult {
        environment.clear()
        
        let lines = source.components(separatedBy: .newlines)
        var parsedLines: [ParsedLine] = []
        var location = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: location, length: lineLength)
            
            if lineIndex < lines.count - 1 {
                location += lineLength + 1
            }
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                parsedLines.append(ParsedLine(
                    lineIndex: lineIndex,
                    sourceRange: lineRange,
                    line: line,
                    statement: nil,
                    usesAggregate: false,
                    parseError: nil
                ))
                continue
            }
            
            let lexer = Lexer(source: line)
            let tokens = lexer.lexAll()
            let parser = Parser(tokens: tokens)
            
            do {
                let stmtOpt = try parser.parseLine()
                if let stmt = stmtOpt {
                    let usesAgg = statementUsesAggregate(stmt)
                    parsedLines.append(ParsedLine(
                        lineIndex: lineIndex,
                        sourceRange: lineRange,
                        line: line,
                        statement: stmt,
                        usesAggregate: usesAgg,
                        parseError: nil
                    ))
                } else {
                    parsedLines.append(ParsedLine(
                        lineIndex: lineIndex,
                        sourceRange: lineRange,
                        line: line,
                        statement: nil,
                        usesAggregate: false,
                        parseError: nil
                    ))
                }
            } catch {
                parsedLines.append(ParsedLine(
                    lineIndex: lineIndex,
                    sourceRange: lineRange,
                    line: line,
                    statement: nil,
                    usesAggregate: false,
                    parseError: error
                ))
            }
        }
        
        let (lineResults, sum) = evaluateWithAggregates(parsedLines: parsedLines)
        return EvaluationResult(lineResults: lineResults, sum: sum)
    }
    
    private func statementUsesAggregate(_ stmt: Statement) -> Bool {
        switch stmt {
        case .expression(let expr):
            return exprUsesAggregate(expr)
        case .assignment(let assignment):
            return exprUsesAggregate(assignment.value)
        }
    }
    
    private func exprUsesAggregate(_ expr: Expr) -> Bool {
        if expr is BuiltinAggregateExpr {
            return true
        }
        switch expr {
        case let b as BinaryExpr:
            return exprUsesAggregate(b.left) || exprUsesAggregate(b.right)
        case let u as UnaryExpr:
            return exprUsesAggregate(u.operand)
        case let p as ParenExpr:
            return exprUsesAggregate(p.inner)
        default:
            return false
        }
    }
    
    private func evaluateWithAggregates(parsedLines: [ParsedLine]) -> (lineResults: [LineResult], sum: Decimal) {
        var results = Array(repeating: LineResult(
            lineIndex: 0,
            sourceRange: NSRange(location: 0, length: 0),
            value: nil,
            error: nil
        ), count: parsedLines.count)
        
        for parsed in parsedLines {
            let idx = parsed.lineIndex
            
            if let error = parsed.parseError {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: error
                )
                continue
            }
            
            guard let statement = parsed.statement else {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: nil
                )
                continue
            }
            
            if parsed.usesAggregate {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: nil
                )
                continue
            }
            
            let evaluator = Evaluator(environment: environment)
            do {
                let value = try evaluator.evaluate(statement)
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: value,
                    error: nil
                )
            } catch {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: error
                )
            }
        }
        
        let aggregates = computeAggregates(from: results, parsedLines: parsedLines)
        
        if let sumValue = aggregates.sum {
            environment[BuiltinAggregateName.sum] = sumValue
        }
        if let avgValue = aggregates.avg {
            environment[BuiltinAggregateName.avg] = avgValue
        }
        
        for parsed in parsedLines where parsed.usesAggregate {
            let idx = parsed.lineIndex
            
            if results[idx].error != nil {
                continue
            }
            
            guard let statement = parsed.statement else {
                continue
            }
            
            let evaluator = Evaluator(environment: environment)
            do {
                let value = try evaluator.evaluate(statement)
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: value,
                    error: nil
                )
            } catch {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: error
                )
            }
        }
        
        return (lineResults: results, sum: aggregates.sumDecimal)
    }
    
    private func computeAggregates(
        from results: [LineResult],
        parsedLines: [ParsedLine]
    ) -> (sum: Value?, avg: Value?, sumDecimal: Decimal) {
        var sumDecimal = Decimal(0)
        var count: Int = 0
        
        for (i, result) in results.enumerated() {
            let parsed = parsedLines[i]
            
            if parsed.usesAggregate { continue }
            guard let value = result.value, let dec = value.asDecimal else { continue }
            
            sumDecimal += dec
            count += 1
        }
        
        guard count > 0 else {
            let zero = Value.quantity(.scalar(0))
            return (sum: zero, avg: zero, sumDecimal: Decimal(0))
        }
        
        let sumValue = Value.quantity(.scalar(sumDecimal))
        let avgValue = Value.quantity(.scalar(sumDecimal / Decimal(count)))
        return (sum: sumValue, avg: avgValue, sumDecimal: sumDecimal)
    }
    
    public func resetEnvironment() {
        environment.clear()
    }
}
