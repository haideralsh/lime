//
//  TestSupport.swift
//  limeTests
//

import Foundation
@testable import lime

func evaluate(_ input: String) -> EvaluationResult {
    let engine = ExpressionEngine()
    return engine.evaluateAll(input)
}
