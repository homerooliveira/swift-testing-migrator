import SwiftSyntax

final class XCTAssertUnifiedRewriter: SyntaxRewriter {
    enum OperatorType: Equatable {
        case equal, notEqual, exclamationMark, identical, notIdentical
        case greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual
        case nilEqual, nilNotEqual
        
        var token: TokenSyntax {
            switch self {
            case .equal, .nilEqual: .binaryOperator("==")
            case .notEqual, .nilNotEqual: .binaryOperator("!=")
            case .exclamationMark: .exclamationMarkToken()
            case .identical: .binaryOperator("===")
            case .notIdentical: .binaryOperator("!==")
            case .greaterThan: .binaryOperator(">")
            case .greaterThanOrEqual: .binaryOperator(">=")
            case .lessThan: .binaryOperator("<")
            case .lessThanOrEqual: .binaryOperator("<=")
            }
        }
        
        var isComparison: Bool {
            switch self {
            case .equal, .notEqual, .identical, .notIdentical, .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual:
                true
            default:
                false
            }
        }
        
        var isNilCheckOperator: Bool {
            switch self {
            case .nilEqual, .nilNotEqual: true
            default: false
            }
        }
    }
    
    private struct AssertionInfo {
        let replacement: String
        let operatorType: OperatorType?
        
        init(_ replacement: String, _ operatorType: OperatorType? = nil) {
            self.replacement = replacement
            self.operatorType = operatorType
        }
    }
    
    private let assertions: [String: AssertionInfo] = [
        // Bool assertions
        "XCTAssertTrue": AssertionInfo("#expect"),
        "XCTAssert": AssertionInfo("#expect"),
        "XCTAssertFalse": AssertionInfo("#expect", .exclamationMark),
        "XCTAssertNil": AssertionInfo("#expect", .nilEqual),
        "XCTAssertNotNil": AssertionInfo("#expect", .nilNotEqual),
        "XCTUnwrap": AssertionInfo("#require"),
        "XCTFail": AssertionInfo("Issue.record"),
        
        // Comparison assertions
        "XCTAssertEqual": AssertionInfo("#expect", .equal),
        "XCTAssertNotEqual": AssertionInfo("#expect", .notEqual),
        "XCTAssertIdentical": AssertionInfo("#expect", .identical),
        "XCTAssertNotIdentical": AssertionInfo("#expect", .notIdentical),
        "XCTAssertGreaterThan": AssertionInfo("#expect", .greaterThan),
        "XCTAssertGreaterThanOrEqual": AssertionInfo("#expect", .greaterThanOrEqual),
        "XCTAssertLessThanOrEqual": AssertionInfo("#expect", .lessThanOrEqual),
        "XCTAssertLessThan": AssertionInfo("#expect", .lessThan)
    ]
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              let assertInfo = assertions[identifierExpr.baseName.text] else {
            return super.visit(node)
        }
        
        var arguments = node.arguments.filter { $0.label == nil }
        
        if let opType = assertInfo.operatorType {
            if opType.isComparison && arguments.count >= 2 {
                return handleComparisonAssertion(node: node, arguments: &arguments, assertInfo: assertInfo, opType: opType)
            } else if arguments.count >= 1 {
                handleSingleArgumentAssertion(arguments: &arguments, opType: opType)
            }
        }
        
        removeTrailingComma(from: &arguments)
        return makeFunctionCall(node: node, arguments: arguments, replacement: assertInfo.replacement)
    }
    
    private func handleComparisonAssertion(
        node: FunctionCallExprSyntax,
        arguments: inout LabeledExprListSyntax,
        assertInfo: AssertionInfo,
        opType: OperatorType
    ) -> ExprSyntax {
        let firstArg = arguments[arguments.startIndex].expression
        let secondIndex = arguments.index(after: arguments.startIndex)
        let secondArg = arguments[secondIndex].expression
        
        let binaryExpr = createBinaryExpression(left: firstArg, operator: opType, right: secondArg)
        arguments[secondIndex].expression = ExprSyntax(binaryExpr)
        arguments.remove(at: arguments.startIndex)
        
        removeTrailingComma(from: &arguments)
        return makeFunctionCall(node: node, arguments: arguments, replacement: assertInfo.replacement)
    }
    
    private func handleSingleArgumentAssertion(arguments: inout LabeledExprListSyntax, opType: OperatorType) {
        let firstArg = arguments[arguments.startIndex]
        
        if opType == .exclamationMark {
            arguments[arguments.startIndex].expression = createPrefixExpression(operator: opType, operand: firstArg)
        } else if opType.isNilCheckOperator {
            let nilExpr = createBinaryExpression(left: firstArg.expression, operator: opType, right: ExprSyntax(NilLiteralExprSyntax()))
            arguments[arguments.startIndex].expression = ExprSyntax(nilExpr)
        }
    }
    
    private func createBinaryExpression(left: ExprSyntax, operator opType: OperatorType, right: ExprSyntax) -> SequenceExprSyntax {
        let binaryExpr = BinaryOperatorExprSyntax(
            leadingTrivia: .space,
            operator: opType.token,
            trailingTrivia: .space
        )
        
        return SequenceExprSyntax(
            elements: ExprListSyntax([left, ExprSyntax(binaryExpr), right])
        )
    }
    
    private func createPrefixExpression(operator opType: OperatorType, operand: LabeledExprSyntax) -> ExprSyntax {
        let newExpression: any ExprSyntaxProtocol = if operand.expression.is(SequenceExprSyntax.self) {
            TupleExprSyntax(elements: LabeledExprListSyntax([operand]))
        } else {
            operand.expression
        }
        
        return ExprSyntax(PrefixOperatorExprSyntax(operator: opType.token, expression: newExpression))
    }
    
    private func removeTrailingComma(from arguments: inout LabeledExprListSyntax) {
        if !arguments.isEmpty {
            arguments[arguments.index(before: arguments.endIndex)].trailingComma = nil
        }
    }
    
    private func makeFunctionCall(node: FunctionCallExprSyntax, arguments: LabeledExprListSyntax, replacement: String) -> ExprSyntax {
        ExprSyntax(
            node
                .with(\.arguments, arguments)
                .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(replacement))))
                .with(\.leadingTrivia, node.leadingTrivia)
        )
    }
}