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
    let usesSubtotal: Bool
    var dependsOnAggregate: Bool
    let parseError: Error?
    
    var assignedVariableName: String? {
        guard case .assignment(let a) = statement else { return nil }
        return a.name
    }
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
                    usesSubtotal: false,
                    dependsOnAggregate: false,
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
                    let usesSub = statementUsesSubtotal(stmt)
                    parsedLines.append(ParsedLine(
                        lineIndex: lineIndex,
                        sourceRange: lineRange,
                        line: line,
                        statement: stmt,
                        usesAggregate: usesAgg,
                        usesSubtotal: usesSub,
                        dependsOnAggregate: false,
                        parseError: nil
                    ))
                } else {
                    parsedLines.append(ParsedLine(
                        lineIndex: lineIndex,
                        sourceRange: lineRange,
                        line: line,
                        statement: nil,
                        usesAggregate: false,
                        usesSubtotal: false,
                        dependsOnAggregate: false,
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
                    usesSubtotal: false,
                    dependsOnAggregate: false,
                    parseError: error
                ))
            }
        }
        
        computeAggregateDependencies(&parsedLines)
        
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
        case let pct as PercentExpr:
            return exprUsesAggregate(pct.operand)
        case let pctOf as PercentOfExpr:
            return exprUsesAggregate(pctOf.percent) || exprUsesAggregate(pctOf.base)
        case let pctAdj as PercentAdjustExpr:
            return exprUsesAggregate(pctAdj.percent) || exprUsesAggregate(pctAdj.base)
        default:
            return false
        }
    }
    
    private func statementUsesSubtotal(_ stmt: Statement) -> Bool {
        switch stmt {
        case .expression(let expr):
            return exprUsesSubtotal(expr)
        case .assignment(let assignment):
            return exprUsesSubtotal(assignment.value)
        }
    }
    
    private func exprUsesSubtotal(_ expr: Expr) -> Bool {
        if expr is SubtotalExpr {
            return true
        }
        switch expr {
        case let b as BinaryExpr:
            return exprUsesSubtotal(b.left) || exprUsesSubtotal(b.right)
        case let u as UnaryExpr:
            return exprUsesSubtotal(u.operand)
        case let p as ParenExpr:
            return exprUsesSubtotal(p.inner)
        case let pct as PercentExpr:
            return exprUsesSubtotal(pct.operand)
        case let pctOf as PercentOfExpr:
            return exprUsesSubtotal(pctOf.percent) || exprUsesSubtotal(pctOf.base)
        case let pctAdj as PercentAdjustExpr:
            return exprUsesSubtotal(pctAdj.percent) || exprUsesSubtotal(pctAdj.base)
        default:
            return false
        }
    }
    
    private func collectVariableReferences(_ expr: Expr) -> Set<String> {
        var refs = Set<String>()
        collectVariableReferencesHelper(expr, into: &refs)
        return refs
    }
    
    private func collectVariableReferencesHelper(_ expr: Expr, into refs: inout Set<String>) {
        switch expr {
        case let v as VariableExpr:
            refs.insert(v.name)
        case let b as BinaryExpr:
            collectVariableReferencesHelper(b.left, into: &refs)
            collectVariableReferencesHelper(b.right, into: &refs)
        case let u as UnaryExpr:
            collectVariableReferencesHelper(u.operand, into: &refs)
        case let p as ParenExpr:
            collectVariableReferencesHelper(p.inner, into: &refs)
        case let pct as PercentExpr:
            collectVariableReferencesHelper(pct.operand, into: &refs)
        case let pctOf as PercentOfExpr:
            collectVariableReferencesHelper(pctOf.percent, into: &refs)
            collectVariableReferencesHelper(pctOf.base, into: &refs)
        case let pctAdj as PercentAdjustExpr:
            collectVariableReferencesHelper(pctAdj.percent, into: &refs)
            collectVariableReferencesHelper(pctAdj.base, into: &refs)
        default:
            break
        }
    }
    
    private func statementVariableReferences(_ stmt: Statement) -> Set<String> {
        switch stmt {
        case .expression(let expr):
            return collectVariableReferences(expr)
        case .assignment(let assignment):
            return collectVariableReferences(assignment.value)
        }
    }
    
    private func computeAggregateDependencies(_ parsedLines: inout [ParsedLine]) {
        var aggregateDependentVars = Set<String>()
        
        for parsed in parsedLines {
            if parsed.usesAggregate || parsed.usesSubtotal {
                if let name = parsed.assignedVariableName {
                    aggregateDependentVars.insert(name)
                }
            }
        }
        
        var changed = true
        while changed {
            changed = false
            for i in parsedLines.indices {
                guard !parsedLines[i].dependsOnAggregate else { continue }
                guard let stmt = parsedLines[i].statement else { continue }
                
                let refs = statementVariableReferences(stmt)
                if !refs.isDisjoint(with: aggregateDependentVars) {
                    parsedLines[i].dependsOnAggregate = true
                    changed = true
                    
                    if let name = parsedLines[i].assignedVariableName {
                        aggregateDependentVars.insert(name)
                    }
                }
            }
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
            
            if parsed.usesAggregate || parsed.usesSubtotal || parsed.dependsOnAggregate {
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
        
        for parsed in parsedLines where parsed.usesAggregate || parsed.dependsOnAggregate {
            let idx = parsed.lineIndex
            
            if results[idx].error != nil {
                continue
            }
            
            guard let statement = parsed.statement else {
                continue
            }
            
            if parsed.usesAggregate {
                var prevValue: Value? = nil
                for i in stride(from: idx - 1, through: 0, by: -1) {
                    if let value = results[i].value {
                        prevValue = value
                        break
                    }
                }
                
                if let pv = prevValue {
                    environment[BuiltinAggregateName.prev] = pv
                } else {
                    environment.remove(BuiltinAggregateName.prev)
                }
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
            } catch let error as EvalError {
                if case .undefinedVariable(let name, _) = error, name == "=prev" {
                    results[idx] = LineResult(
                        lineIndex: idx,
                        sourceRange: parsed.sourceRange,
                        value: nil,
                        error: nil
                    )
                } else {
                    results[idx] = LineResult(
                        lineIndex: idx,
                        sourceRange: parsed.sourceRange,
                        value: nil,
                        error: error
                    )
                }
            } catch {
                results[idx] = LineResult(
                    lineIndex: idx,
                    sourceRange: parsed.sourceRange,
                    value: nil,
                    error: error
                )
            }
        }
        
        results = evaluateSubtotals(results: results, parsedLines: parsedLines)
        
        return (lineResults: results, sum: aggregates.sumDecimal)
    }
    
    private func evaluateSubtotals(results: [LineResult], parsedLines: [ParsedLine]) -> [LineResult] {
        var results = results
        
        var segmentSumDecimal: Decimal = 0
        var segmentCurrencyUnit: Unit? = nil
        var segmentMixedCurrencies = false
        
        for parsed in parsedLines {
            let idx = parsed.lineIndex
            
            if parsed.usesSubtotal {
                guard let statement = parsed.statement else { continue }
                
                let unitForSubtotal: Unit? = segmentMixedCurrencies ? nil : segmentCurrencyUnit
                let subtotalValue = Value.quantity(Quantity(magnitude: segmentSumDecimal, unit: unitForSubtotal))
                environment[BuiltinAggregateName.subtotal] = subtotalValue
                
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
                
                segmentSumDecimal = 0
                segmentCurrencyUnit = nil
                segmentMixedCurrencies = false
            } else if !parsed.usesAggregate {
                guard let value = results[idx].value else { continue }
                guard case .quantity(let q) = value else { continue }
                
                segmentSumDecimal += q.magnitude
                
                if let unit = q.unit, unit.kind == .currency {
                    if let existing = segmentCurrencyUnit {
                        if existing != unit {
                            segmentMixedCurrencies = true
                        }
                    } else {
                        segmentCurrencyUnit = unit
                    }
                }
            }
        }
        
        return results
    }
    
    private func computeAggregates(
        from results: [LineResult],
        parsedLines: [ParsedLine]
    ) -> (sum: Value?, avg: Value?, sumDecimal: Decimal) {
        var sumDecimal = Decimal(0)
        var count: Int = 0
        var aggregateCurrencyUnit: Unit? = nil
        var mixedCurrencies = false
        
        for (i, result) in results.enumerated() {
            let parsed = parsedLines[i]
            
            if parsed.usesAggregate || parsed.usesSubtotal || parsed.dependsOnAggregate { continue }
            guard let value = result.value else { continue }
            guard case .quantity(let q) = value else { continue }
            
            sumDecimal += q.magnitude
            count += 1
            
            if let unit = q.unit, unit.kind == .currency {
                if let existing = aggregateCurrencyUnit {
                    if existing != unit {
                        mixedCurrencies = true
                    }
                } else {
                    aggregateCurrencyUnit = unit
                }
            }
        }
        
        guard count > 0 else {
            let zero = Value.quantity(.scalar(0))
            return (sum: zero, avg: zero, sumDecimal: Decimal(0))
        }
        
        let unitForAggregates: Unit? = mixedCurrencies ? nil : aggregateCurrencyUnit
        
        let sumValue = Value.quantity(Quantity(magnitude: sumDecimal, unit: unitForAggregates))
        let avgValue = Value.quantity(Quantity(magnitude: sumDecimal / Decimal(count), unit: unitForAggregates))
        return (sum: sumValue, avg: avgValue, sumDecimal: sumDecimal)
    }
    
    public func resetEnvironment() {
        environment.clear()
    }
}
